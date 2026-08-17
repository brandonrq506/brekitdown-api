defmodule BrekitdownWeb.Schemas.Task do
  @moduledoc "Public representation of a task (never the internal ids)."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Tag
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Task",
    description: "A task as exposed by the API",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, maxLength: 100},
      status: %Schema{
        type: :string,
        enum: ["scheduled", "in_progress", "completed", "dropped", "on_hold"]
      },
      due_at: %Schema{type: :string, format: :"date-time", nullable: true},
      goal_reference_xid: %Schema{type: :string, format: :uuid, nullable: true},
      parent_reference_xid: %Schema{type: :string, format: :uuid, nullable: true},
      tags: %Schema{type: :array, items: Tag},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:reference_xid, :name, :status, :inserted_at, :updated_at],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Finish writing the report",
      status: "scheduled",
      due_at: "2024-06-30T12:00:00Z",
      goal_reference_xid: "123e4567-e89b-12d3-a456-426614174001",
      parent_reference_xid: "123e4567-e89b-12d3-a456-426614174002",
      tags: [],
      inserted_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:00:00Z"
    }
  })
end
