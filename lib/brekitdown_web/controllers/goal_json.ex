defmodule BrekitdownWeb.GoalJSON do
  alias Brekitdown.Goals.Goal

  @doc """
  Renders a list of goals.
  """
  def index(%{goals: goals}) do
    %{data: for(goal <- goals, do: data(goal))}
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
      name: goal.name
    }
  end
end
