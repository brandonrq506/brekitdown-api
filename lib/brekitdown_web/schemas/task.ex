defmodule BrekitdownWeb.Schemas.Task do
  @moduledoc "Public representation of a task (never the internal ids)."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Tag
  alias BrekitdownWeb.Schemas.TaskStatus
  alias BrekitdownWeb.Schemas.TimeEntry
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Task",
    description: "A task as exposed by the API",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, maxLength: 100},
      description: %Schema{type: :string, maxLength: 2000},
      status: TaskStatus,
      due_at: %Schema{type: :string, format: :"date-time", nullable: true},
      goal: %Schema{
        type: :object,
        nullable: true,
        description: "The goal this task belongs to; null when it has none.",
        properties: %{
          reference_xid: %Schema{type: :string, format: :uuid},
          name: %Schema{type: :string, maxLength: 100}
        },
        required: [:reference_xid, :name]
      },
      parent_reference_xid: %Schema{type: :string, format: :uuid, nullable: true},
      has_children: %Schema{type: :boolean},
      notes_count: %Schema{
        type: :integer,
        minimum: 0,
        description: "Fetch the notes themselves from /api/tasks/{task_id}/notes."
      },
      tags: %Schema{type: :array, items: Tag},
      time_entries: %Schema{type: :array, items: TimeEntry},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [
      :reference_xid,
      :name,
      :description,
      :status,
      :has_children,
      :notes_count,
      :inserted_at,
      :updated_at
    ],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Finish writing the report",
      description: "Complete the final sections and review the report for accuracy.",
      status: "scheduled",
      due_at: "2024-06-30T12:00:00Z",
      goal: %{
        reference_xid: "123e4567-e89b-12d3-a456-426614174001",
        name: "Ship the quarterly report"
      },
      parent_reference_xid: "123e4567-e89b-12d3-a456-426614174002",
      has_children: true,
      notes_count: 1,
      tags: [],
      time_entries: [
        %{
          reference_xid: "123e4567-e89b-12d3-a456-426614174003",
          started_at: "2024-06-30T09:00:00Z",
          ended_at: "2024-06-30T10:00:00Z",
          inserted_at: "2024-06-30T09:00:00Z",
          updated_at: "2024-06-30T10:00:00Z"
        }
      ],
      inserted_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:00:00Z"
    }
  })
end
