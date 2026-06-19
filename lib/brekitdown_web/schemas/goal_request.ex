defmodule BrekitdownWeb.Schemas.GoalRequest do
  @moduledoc "Request body for creating/updating a goal: a nested goal object."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalRequest",
    type: :object,
    properties: %{
      goal: %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          description: %Schema{type: :string, nullable: true}
        },
        required: [:name]
      }
    },
    required: [:goal]
  })
end
