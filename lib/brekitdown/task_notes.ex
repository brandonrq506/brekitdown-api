defmodule Brekitdown.TaskNotes do
  @moduledoc """
  The TaskNotes context.
  """

  import Ecto.Query, warn: false

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Repo
  alias Brekitdown.TaskNotes.TaskNote
  alias Brekitdown.Tasks.Task

  @doc """
  Returns the list of notes for a task, newest first.

  ## Examples

      iex> list_task_notes_by_task(scope, task)
      [%TaskNote{}, ...]

  """
  def list_task_notes_by_task(%Scope{} = scope, %Task{} = task) do
    true = task.user_id == scope.user.id

    TaskNote
    |> where([n], n.task_id == ^task.id)
    |> order_by([n], desc: n.inserted_at, desc: n.id)
    |> Repo.all()
  end

  @doc """
  Gets a single note for a task.

  Raises `Ecto.NoResultsError` if the TaskNote does not exist.

  Scoped by `task_id` *and* `reference_xid`, so asking for a real note under the wrong
  task is a 404 rather than a silent success.

  ## Examples

      iex> get_task_note!(scope, task, "550e8400-e29b-41d4-a716-446655440000")
      %TaskNote{}

      iex> get_task_note!(scope, task, "550e8400-e29b-41d4-a716-446655440001")
      ** (Ecto.NoResultsError)

  """
  def get_task_note!(%Scope{} = scope, %Task{} = task, reference_xid) do
    true = task.user_id == scope.user.id

    Repo.get_by!(TaskNote, task_id: task.id, reference_xid: reference_xid)
  end

  @doc """
  Creates a note on a task.

  ## Examples

      iex> create_task_note(scope, task, %{title: "Stuck", body: "..."})
      {:ok, %TaskNote{}}

      iex> create_task_note(scope, task, %{title: "", body: ""})
      {:error, %Ecto.Changeset{}}

  """
  def create_task_note(%Scope{} = scope, %Task{} = task, attrs) do
    true = task.user_id == scope.user.id

    with {:ok, task_note = %TaskNote{}} <-
           %TaskNote{}
           |> TaskNote.create_changeset(attrs, task)
           |> Repo.insert() do
      {:ok, task_note}
    end
  end

  @doc """
  Updates a note.
  """
  def update_task_note(%Scope{} = scope, %Task{} = task, %TaskNote{} = task_note, attrs) do
    true = task.user_id == scope.user.id
    true = task_note.task_id == task.id

    with {:ok, task_note = %TaskNote{}} <-
           task_note
           |> TaskNote.update_changeset(attrs)
           |> Repo.update() do
      {:ok, task_note}
    end
  end

  @doc """
  Deletes a note.
  """
  def delete_task_note(%Scope{} = scope, %Task{} = task, %TaskNote{} = task_note) do
    true = task.user_id == scope.user.id
    true = task_note.task_id == task.id

    with {:ok, task_note = %TaskNote{}} <- Repo.delete(task_note) do
      {:ok, task_note}
    end
  end
end
