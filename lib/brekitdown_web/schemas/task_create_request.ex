defmodule BrekitdownWeb.Schemas.TaskCreateRequest do
  @moduledoc "Request body for creating a task: a nested task object."
  require OpenApiSpex

  alias BrekitdownWeb.Schemas.TaskStatus
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskCreateRequest",
    type: :object,
    properties: %{
      task: %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          description: %Schema{type: :string, maxLength: 2000},
          status: TaskStatus,
          due_at: %Schema{type: :string, format: :"date-time", nullable: true},
          goal_reference_xid: %Schema{type: :string, format: :uuid, nullable: true},
          parent_reference_xid: %Schema{type: :string, format: :uuid, nullable: true}
        },
        required: [:name]
      }
    },
    required: [:task]
  })
end
