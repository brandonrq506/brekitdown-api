defmodule Brekitdown.TimeEntries do
  @moduledoc """
  The TimeEntries context.
  """

  import Ecto.Query, warn: false
  alias Brekitdown.Repo

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Tasks
  alias Brekitdown.Tasks.Task
  alias Brekitdown.Tasks.TaskStatuses
  alias Brekitdown.TimeEntries.TimeEntry

  @doc """
  Returns the list of time_entries for a task.

  ## Examples

      iex> list_time_entries_by_task(scope, task)
      [%TimeEntry{}, ...]

  """
  def list_time_entries_by_task(%Scope{} = scope, %Task{} = task) do
    TimeEntry
    |> where([te], te.task_id == ^task.id)
    |> order_by([te], asc: te.started_at)
    |> Repo.all_by(user_id: scope.user.id)
  end

  @doc """
  Gets a single time_entry for a task.

  Raises `Ecto.NoResultsError` if the TimeEntry does not exist.

  ## Examples

      iex> get_time_entry!(scope, task, "550e8400-e29b-41d4-a716-446655440000")
      %TimeEntry{}

      iex> get_time_entry!(scope, task, "550e8400-e29b-41d4-a716-446655440001")
      ** (Ecto.NoResultsError)

  """
  def get_time_entry!(%Scope{} = scope, %Task{} = task, reference_xid) do
    Repo.get_by!(TimeEntry,
      user_id: scope.user.id,
      task_id: task.id,
      reference_xid: reference_xid
    )
  end

  @doc """
  Gets a single time_entry for a task.

  Returns nil if the TimeEntry does not exist.

  ## Examples

      iex> get_time_entry(scope, task, "550e8400-e29b-41d4-a716-446655440000")
      %TimeEntry{}

      iex> get_time_entry(scope, task, "550e8400-e29b-41d4-a716-446655440001")
      nil

  """
  def get_time_entry(%Scope{} = scope, %Task{} = task, reference_xid) do
    Repo.get_by(TimeEntry,
      user_id: scope.user.id,
      task_id: task.id,
      reference_xid: reference_xid
    )
  end

  @doc """
  Creates a time_entry for a task, and moves the task's status when the new entry says
  work is happening.

  A running entry (no `ended_at`) claims work is happening *now*, so it puts the task in
  progress whatever it was. A finished entry only claims work happened, so it starts a
  task that is still `:scheduled` and leaves a deliberate status alone — logging time
  against something you dropped does not un-drop it.

  ## Examples

      iex> create_time_entry(scope, task, %{field: value})
      {:ok, %TimeEntry{}}

      iex> create_time_entry(scope, task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_time_entry(%Scope{} = scope, %Task{} = task, attrs) do
    true = task.user_id == scope.user.id

    changeset = TimeEntry.create_changeset(%TimeEntry{}, attrs, scope, task)

    with :ok <- ensure_leaf(task),
         :ok <- ensure_no_open_entry(changeset, task.id) do
      write_and_update_status(scope, task, changeset)
    end
  end

  @doc """
  Updates a time_entry for a task, and moves the task's status by the same rule as
  `create_time_entry/3`, applied to the entry the edit leaves behind.

  Un-stopping an entry (clearing `ended_at`) means work is being done on it, so it puts the task in progress. Stopping an entry, or correcting its timestamps,
  claims nothing about the task now and leaves a deliberate status alone.

  ## Examples

      iex> update_time_entry(scope, task, time_entry, %{field: new_value})
      {:ok, %TimeEntry{}}

      iex> update_time_entry(scope, task, time_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_time_entry(%Scope{} = scope, %Task{} = task, %TimeEntry{} = time_entry, attrs) do
    true = time_entry.user_id == scope.user.id
    true = time_entry.task_id == task.id

    changeset = TimeEntry.update_changeset(time_entry, attrs)

    with :ok <- ensure_no_open_entry(changeset, task.id, time_entry.id) do
      write_and_update_status(scope, task, changeset)
    end
  end

  @doc """
  Deletes a time_entry from a task and updates the task status if necessary.

  ## Examples

      iex> delete_time_entry(scope, task, time_entry)
      {:ok, %TimeEntry{}}

      iex> delete_time_entry(scope, task, time_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_time_entry(%Scope{} = scope, %Task{} = task, %TimeEntry{} = time_entry) do
    true = time_entry.user_id == scope.user.id
    true = time_entry.task_id == task.id

    Repo.transact(fn ->
      with {:ok, time_entry} <- Repo.delete(time_entry),
           status = status_after_delete(task.status, task_has_entries?(task)),
           {:ok, _task} <- Tasks.update_status(scope, task, status) do
        {:ok, time_entry}
      end
    end)
  end

  @doc """
  Returns true when a task has at least one time entry.

  ## Examples

      iex> task_has_entries?(task)
      true

  """
  def task_has_entries?(%Task{} = task) do
    TimeEntry
    |> where([te], te.task_id == ^task.id)
    |> Repo.exists?()
  end

  # Both writes or neither: an entry the task's status does not reflect is a lie the next
  # read would tell. `insert_or_update/1` dispatches on the changeset's data state, so create
  # and update share one transaction and one rule rather than drifting apart. A function of
  # its own because inlining it nests with -> fn -> with, one level past
  # Credo.Check.Refactor.Nesting's max_nesting: 2.
  defp write_and_update_status(scope, task, changeset) do
    Repo.transact(fn ->
      with {:ok, time_entry} <- Repo.insert_or_update(changeset),
           status = status_with_entry(task.status, TimeEntry.state(time_entry)),
           {:ok, _task} <- Tasks.update_status(scope, task, status) do
        {:ok, time_entry}
      end
    end)
  end

  defp ensure_leaf(%Task{} = task) do
    case Tasks.leaf?(task) do
      true -> :ok
      false -> {:error, :not_a_leaf_task}
    end
  end

  # A task may have at most one running entry. Checked here rather than left to
  # :time_entries_one_open_per_task_index so the failure is a 409 on task state,
  # not a 422 on a column the client never sent. The index stays as the backstop.
  defp ensure_no_open_entry(changeset, task_id, except_id \\ nil) do
    if entry_open?(changeset) and open_entry_exists?(task_id, except_id) do
      {:error, :entry_already_running}
    else
      :ok
    end
  end

  defp entry_open?(changeset), do: is_nil(Ecto.Changeset.get_field(changeset, :ended_at))

  defp open_entry_exists?(task_id, except_id) do
    TimeEntry
    |> where([te], te.task_id == ^task_id and is_nil(te.ended_at))
    |> exclude_entry(except_id)
    |> Repo.exists?()
  end

  defp exclude_entry(query, nil), do: query
  defp exclude_entry(query, id), do: where(query, [te], te.id != ^id)

  # Status describes the task now, so only a present-tense claim may override a status the
  # user chose. `:open` is one; `:closed` is a claim about the past and can only contradict
  # `:scheduled`, which is itself the claim that nothing has been worked on yet. Keyed on the
  # entry that now exists, not on the verb that wrote it, so creating an open entry and
  # un-stopping one cannot disagree.
  defp status_with_entry(_status, :open), do: :in_progress
  defp status_with_entry(:scheduled, :closed), do: :in_progress
  defp status_with_entry(status, :closed), do: status

  defp status_after_delete(:in_progress, false), do: TaskStatuses.default()
  defp status_after_delete(status, _), do: status
end
