defmodule BrekitdownWeb.GoalJSON do
  alias Brekitdown.Goals.Goal
  alias BrekitdownWeb.PaginationJSON

  @doc """
  Renders a list of goals.
  """
  def index(%{goals: goals, flop_meta: flop_meta}) do
    %{
      data: for(goal <- goals, do: data(goal)),
      meta: PaginationJSON.pagination_meta(flop_meta)
    }
  end

  @doc """
  Renders a single goal.
  """
  def show(%{goal: goal}) do
    %{data: data(goal)}
  end

  defp data(%Goal{} = goal) do
    %{
      reference_xid: goal.reference_xid,
      description: goal.description,
      name: goal.name,
      inserted_at: goal.inserted_at,
      updated_at: goal.updated_at
    }
  end
end
