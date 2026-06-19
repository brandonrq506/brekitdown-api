defmodule BrekitdownWeb.Schemas.GoalResponse do
  @moduledoc "Single-goal response envelope: %{data: Goal}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Goal

  OpenApiSpex.schema(%{
    title: "GoalResponse",
    type: :object,
    properties: %{data: Goal},
    required: [:data]
  })
end
