defmodule Brekitdown.GoalsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.Goals` context.
  """

  @doc """
  Generate a goal.
  """
  def goal_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, goal} = Brekitdown.Goals.create_goal(scope, attrs)
    goal
  end
end
