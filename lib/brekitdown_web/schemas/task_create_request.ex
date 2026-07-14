defmodule BrekitdownWeb.Schemas.TaskCreateRequest do
  @moduledoc "Request body for creating a task: a nested task object."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskCreateRequest",
    type: :object,
    properties: %{
      task: %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          status: %Schema{
            type: :string,
            enum: ["scheduled", "in_progress", "completed", "dropped", "on_hold"]
          },
          due_at: %Schema{type: :string, format: :date_time, nullable: true},
          goal_reference_xid: %Schema{type: :string, format: :uuid, nullable: true}
        },
        required: [:name]
      }
    },
    required: [:task]
  })
end
