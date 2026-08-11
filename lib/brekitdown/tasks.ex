defmodule Brekitdown.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Brekitdown.Repo

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Goals
  alias Brekitdown.Tags
  alias Brekitdown.Tags.TaskTag
  alias Brekitdown.Tasks.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks(scope)
      [%Task{}, ...]

  """
  def list_tasks(scope, preload \\ [])

  def list_tasks(%Scope{} = scope, preload) do
    Task
    |> preload(^preload)
    |> Repo.all_by(user_id: scope.user.id)
  end

  @doc """
  Returns the list of child tasks for a given parent task.

  ## Examples

      iex> list_children(scope, parent_task)
      [%Task{}, ...]

  """
  def list_children(scope, parent, preload \\ [])

  def list_children(%Scope{} = scope, %Task{} = parent, preload) do
    Task
    |> preload(^preload)
    |> Repo.all_by(user_id: scope.user.id, parent_id: parent.id)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Task{}

      iex> get_task!(scope, "550e8400-e29b-41d4-a716-446655440001")
      ** (Ecto.NoResultsError)

  """
  def get_task!(scope, reference_xid, preload \\ [])

  def get_task!(%Scope{} = scope, reference_xid, preload) do
    Task
    |> preload(^preload)
    |> Repo.get_by!(reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Gets a single task.

  Returns nil if the Task does not exist.

  ## Examples

      iex> get_task(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Task{}

      iex> get_task(scope, "550e8400-e29b-41d4-a716-446655440001")
      nil
  """
  def get_task(scope, reference_xid, preload \\ [])

  def get_task(%Scope{} = scope, reference_xid, preload) do
    Task
    |> preload(^preload)
    |> Repo.get_by(reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(scope, %{field: value})
      {:ok, %Task{}}

      iex> create_task(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(%Scope{} = scope, attrs) do
    with {:ok, task = %Task{}} <-
           %Task{}
           |> Task.create_changeset(attrs, scope)
           |> put_parent_and_goal(scope, attrs[:parent_reference_xid], attrs[:goal_reference_xid])
           |> Repo.insert() do
      {:ok, task}
    end
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(scope, task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(scope, task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Scope{} = scope, %Task{} = task, attrs) do
    true = task.user_id == scope.user.id

    with {:ok, task = %Task{}} <-
           task
           |> Task.update_changeset(attrs)
           |> Repo.update() do
      {:ok, task}
    end
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(scope, task)
      {:ok, %Task{}}

      iex> delete_task(scope, task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Scope{} = scope, %Task{} = task) do
    true = task.user_id == scope.user.id

    with {:ok, task = %Task{}} <-
           Repo.delete(task) do
      {:ok, task}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(scope, task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Scope{} = scope, %Task{} = task, attrs \\ %{}) do
    true = task.user_id == scope.user.id

    Task.create_changeset(task, attrs, scope)
  end

  @doc """
  Returns true if the task is a leaf (has no children), false otherwise.

  ## Examples

      iex> leaf?(task)
      true

  """
  def leaf?(%Task{} = task) do
    not Repo.exists?(from t in Task, where: t.parent_id == ^task.id)
  end

  @doc """
  Attaches a tag to a task.

  ## Examples

      iex> attach_tag(scope, task, "tag_name")
      {:ok, %Task{}}

      iex> attach_tag(scope, task, "   ")
      {:error, %Ecto.Changeset{}}

  """
  def attach_tag(scope, task, name, preload \\ [])

  def attach_tag(%Scope{} = scope, %Task{} = task, name, preload) do
    true = task.user_id == scope.user.id

    with {:ok, tag} <- Tags.find_or_create_tag(scope, name) do
      Repo.insert(%TaskTag{task_id: task.id, tag_id: tag.id},
        on_conflict: :nothing,
        conflict_target: [:task_id, :tag_id]
      )

      {:ok, Repo.preload(task, preload, force: true)}
    end
  end

  @doc """
  Detaches a tag from a task.

  ## Examples

      iex> detach_tag(scope, task, "550e8400-e29b-41d4-a716-446655440000")
      :ok

  """
  def detach_tag(%Scope{} = scope, %Task{} = task, tag_reference_xid) do
    true = task.user_id == scope.user.id
    tag = Tags.get_tag!(scope, tag_reference_xid)

    from(tt in TaskTag, where: tt.task_id == ^task.id and tt.tag_id == ^tag.id)
    |> Repo.delete_all()

    :ok
  end

  def update_status(%Scope{} = scope, %Task{} = task, status) do
    true = task.user_id == scope.user.id

    task
    |> Task.status_changeset(status)
    |> Repo.update()
  end

  defp maybe_put_goal(changeset, _scope, nil), do: changeset

  defp maybe_put_goal(changeset, scope, goal_reference_xid) do
    case Goals.get_goal(scope, goal_reference_xid) do
      nil -> Ecto.Changeset.add_error(changeset, :goal_reference_xid, "does not exist")
      goal -> Ecto.Changeset.put_change(changeset, :goal_id, goal.id)
    end
  end

  defp validate_goal_matches_parent(changeset, _scope, _parent, nil), do: changeset

  defp validate_goal_matches_parent(changeset, scope, parent, goal_reference_xid) do
    case Goals.get_goal(scope, goal_reference_xid) do
      nil ->
        Ecto.Changeset.add_error(changeset, :goal_reference_xid, "does not exist")

      goal ->
        if parent.goal_id == goal.id do
          changeset
        else
          Ecto.Changeset.add_error(
            changeset,
            :goal_reference_xid,
            "must match the parent's goal; a child inherits its parent's goal"
          )
        end
    end
  end

  # When no parent, goal is optional and independent.
  defp put_parent_and_goal(changeset, scope, nil, goal_reference_xid),
    do: maybe_put_goal(changeset, scope, goal_reference_xid)

  defp put_parent_and_goal(changeset, scope, parent_reference_xid, goal_reference_xid) do
    case get_task(scope, parent_reference_xid) do
      nil ->
        Ecto.Changeset.add_error(changeset, :parent_reference_xid, "does not exist")

      parent ->
        changeset
        |> Ecto.Changeset.put_change(:parent_id, parent.id)
        |> Ecto.Changeset.put_change(:goal_id, parent.goal_id)
        |> validate_goal_matches_parent(scope, parent, goal_reference_xid)
    end
  end
end
