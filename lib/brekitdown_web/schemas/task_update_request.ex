defmodule BrekitdownWeb.Schemas.TaskUpdateRequest do
  @moduledoc "Request body for updating a task: name and due_at only."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskUpdateRequest",
    type: :object,
    properties: %{
      task: %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, maxLength: 100},
          due_at: %Schema{type: :string, format: :"date-time", nullable: true}
        },
        required: [:name]
      }
    },
    required: [:task]
  })
end
