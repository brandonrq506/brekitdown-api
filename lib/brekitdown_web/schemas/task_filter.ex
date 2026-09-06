defmodule BrekitdownWeb.Schemas.TaskFilter do
  @moduledoc "One Flop filter accepted by GET /api/tasks"

  require OpenApiSpex
  alias Brekitdown.Tasks.Task
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(
    %{
      title: "TaskFilter",
      description:
        "A single Flop Filter. Sent as `filters[<index>][field]`, `filters[<index>][op]`, and `filters[<index>][value]`. Filters combine with AND.",
      type: :object,
      properties: %{
        field: %Schema{
          type: :string,
          enum: Enum.map(Flop.Schema.filterable(%Task{}), &Atom.to_string/1),
          description: "`goal_reference_xid`: The reference_xid of the task's goal."
        },
        op: %Schema{
          type: :string,
          enum: ["=="],
          description: "The exact Flop operator string. Only equality is supported."
        },
        value: %Schema{
          type: :string,
          format: :uuid,
          description: "The goal's reference_xid."
        }
      },
      required: [:field, :op, :value],
      additionalProperties: false,
      example: %{
        field: "goal_reference_xid",
        op: "==",
        value: "123e4567-e89b-12d3-a456-426614174000"
      }
    },
    struct?: false
  )
end
