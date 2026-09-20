defmodule BrekitdownWeb.Schemas.TaskUpdateRequest do
  @moduledoc "Request body for updating a task: name, description, status, and due_at only."
  require OpenApiSpex

  alias BrekitdownWeb.Schemas.TaskStatus
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskUpdateRequest",
    type: :object,
    properties: %{
      task: %Schema{
        type: :object,
        minProperties: 1,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          description: %Schema{type: :string, maxLength: 2000},
          status: TaskStatus,
          due_at: %Schema{type: :string, format: :"date-time", nullable: true}
        }
      }
    },
    required: [:task]
  })
end
