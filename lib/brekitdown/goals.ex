defmodule Brekitdown.Goals do
  @moduledoc """
  The Goals context.
  """

  import Ecto.Query, warn: false
  alias Brekitdown.Repo

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Goals.Goal

  @doc """
  Subscribes to scoped notifications about any goal changes.

  The broadcasted messages match the pattern:

    * {:created, %Goal{}}
    * {:updated, %Goal{}}
    * {:deleted, %Goal{}}

  """
  def subscribe_goals(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Brekitdown.PubSub, "user:#{key}:goals")
  end

  defp broadcast_goal(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Brekitdown.PubSub, "user:#{key}:goals", message)
  end

  @doc """
  Returns a paginated list of goals for the current scope.

  ## Examples

      iex> paginated_list(scope, %{page: 1, page_size: 20})
      {:ok, {[%Goal{}, ...], %Flop.Meta{}}}

  """
  def paginated_list(%Scope{} = scope, flop_params \\ %{}, preloads \\ []) do
    Goal
    |> where(user_id: ^scope.user.id)
    |> preload(^preloads)
    |> Flop.validate_and_run(flop_params, for: Goal, filtering: false, ordering: false)
  end

  @doc """
  Gets a single goal.

  Raises `Ecto.NoResultsError` if the Goal does not exist.

  ## Examples

      iex> get_goal!(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Goal{}

      iex> get_goal!(scope, "550e8400-e29b-41d4-a716-446655440001")
      ** (Ecto.NoResultsError)

  """
  def get_goal!(%Scope{} = scope, reference_xid) do
    Repo.get_by!(Goal, reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Gets a single goal.

  ## Examples

      iex> get_goal(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Goal{}

      iex> get_goal(scope, "550e8400-e29b-41d4-a716-446655440001")
      nil

  """
  def get_goal(%Scope{} = scope, reference_xid) do
    Repo.get_by(Goal, reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Creates a goal.

  ## Examples

      iex> create_goal(scope, %{field: value})
      {:ok, %Goal{}}

      iex> create_goal(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_goal(%Scope{} = scope, attrs) do
    with {:ok, goal = %Goal{}} <-
           %Goal{}
           |> Goal.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_goal(scope, {:created, goal})
      {:ok, goal}
    end
  end

  @doc """
  Updates a goal.

  ## Examples

      iex> update_goal(scope, goal, %{field: new_value})
      {:ok, %Goal{}}

      iex> update_goal(scope, goal, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_goal(%Scope{} = scope, %Goal{} = goal, attrs) do
    true = goal.user_id == scope.user.id

    with {:ok, goal = %Goal{}} <-
           goal
           |> Goal.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_goal(scope, {:updated, goal})
      {:ok, goal}
    end
  end

  @doc """
  Deletes a goal.

  ## Examples

      iex> delete_goal(scope, goal)
      {:ok, %Goal{}}

      iex> delete_goal(scope, goal)
      {:error, %Ecto.Changeset{}}

  """
  def delete_goal(%Scope{} = scope, %Goal{} = goal) do
    true = goal.user_id == scope.user.id

    with {:ok, goal = %Goal{}} <-
           Repo.delete(goal) do
      broadcast_goal(scope, {:deleted, goal})
      {:ok, goal}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking goal changes.

  ## Examples

      iex> change_goal(scope, goal)
      %Ecto.Changeset{data: %Goal{}}

  """
  def change_goal(%Scope{} = scope, %Goal{} = goal, attrs \\ %{}) do
    true = goal.user_id == scope.user.id

    Goal.changeset(goal, attrs, scope)
  end
end
