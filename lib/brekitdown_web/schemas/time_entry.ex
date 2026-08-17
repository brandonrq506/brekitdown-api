defmodule BrekitdownWeb.Schemas.TimeEntry do
  @moduledoc "Public representation of a time entry (never the internal ids)."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TimeEntry",
    description: "A time entry as exposed by the API",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      started_at: %Schema{type: :string, format: :"date-time"},
      ended_at: %Schema{type: :string, format: :"date-time", nullable: true},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:reference_xid, :started_at, :ended_at, :inserted_at, :updated_at],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      started_at: "2024-06-30T09:00:00Z",
      ended_at: "2024-06-30T10:00:00Z",
      inserted_at: "2024-06-30T09:00:00Z",
      updated_at: "2024-06-30T10:00:00Z"
    }
  })
end
