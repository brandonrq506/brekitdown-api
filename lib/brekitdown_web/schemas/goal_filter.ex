defmodule BrekitdownWeb.Schemas.GoalFilter do
  @moduledoc "One Flop filter accepted by GET /api/goals"

  require OpenApiSpex
  alias Brekitdown.Goals.Goal
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(
    %{
      title: "GoalFilter",
      description:
        "A single Flop Filter. Sent as `filters[<index>][field]`, `filters[<index>][op]`, and `filters[<index>][value]`. Filters combine with AND.",
      type: :object,
      properties: %{
        field: %Schema{
          type: :string,
          enum: Enum.map(Flop.allowed_fields(:filterable, for: Goal), &Atom.to_string/1),
          description: "`completed`: whether the goal is a Completed goal."
        },
        op: %Schema{
          type: :string,
          enum: ["=="],
          description: "The exact Flop operator string. Only equality is supported."
        },
        value: %Schema{
          type: :boolean,
          description: "`true` returns only Completed goals; `false` excludes them."
        }
      },
      required: [:field, :op, :value],
      additionalProperties: false,
      example: %{field: "completed", op: "==", value: false}
    },
    struct?: false
  )
end
