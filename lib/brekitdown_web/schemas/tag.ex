defmodule BrekitdownWeb.Schemas.Tag do
  @moduledoc "Public representation of a tag (never the internal ids)."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Tag",
    description: "A tag as exposed by the API",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      name: %Schema{type: :string, maxLength: 50},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:reference_xid, :name, :inserted_at, :updated_at],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Urgent",
      inserted_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:00:00Z"
    }
  })
end
