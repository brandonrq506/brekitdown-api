defmodule Brekitdown.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Brekitdown.Repo

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Goals
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
           |> maybe_put_goal(scope, attrs[:goal_reference_xid])
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

  defp maybe_put_goal(changeset, _scope, nil), do: changeset

  defp maybe_put_goal(changeset, scope, goal_reference_xid) do
    case Goals.get_goal(scope, goal_reference_xid) do
      nil -> Ecto.Changeset.add_error(changeset, :goal_reference_xid, "does not exist")
      goal -> Ecto.Changeset.put_change(changeset, :goal_id, goal.id)
    end
  end
end
