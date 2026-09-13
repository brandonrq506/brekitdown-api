defmodule BrekitdownWeb.Schemas.Goal do
  @moduledoc "Public representation of a goal (never the internal id or user_id)."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Goal",
    description: "A goal as exposed by the API (never id or user_id)",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, maxLength: 100},
      description: %Schema{type: :string, nullable: true},
      archived_at: %Schema{type: :string, format: :"date-time", nullable: true},
      starred_at: %Schema{type: :string, format: :"date-time", nullable: true},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [
      :reference_xid,
      :name,
      :archived_at,
      :starred_at,
      :inserted_at,
      :updated_at
    ],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Learn to use Claude",
      description: "Become more valuable and efficient at work",
      archived_at: nil,
      starred_at: "2024-01-02T12:00:00Z",
      inserted_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:00:00Z"
    }
  })
end
