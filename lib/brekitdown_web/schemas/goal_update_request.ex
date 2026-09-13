defmodule BrekitdownWeb.Schemas.GoalUpdateRequest do
  @moduledoc "Request body for partially updating a goal: a nested goal object."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalUpdateRequest",
    type: :object,
    properties: %{
      goal: %Schema{
        type: :object,
        minProperties: 1,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          description: %Schema{type: :string, nullable: true},
          archived_at: %Schema{type: :string, format: :"date-time", nullable: true},
          starred_at: %Schema{type: :string, format: :"date-time", nullable: true}
        }
      }
    },
    required: [:goal]
  })
end
