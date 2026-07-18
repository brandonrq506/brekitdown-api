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
      name: %Schema{type: :string, maxLength: 100}
    },
    required: [:reference_xid, :name],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Urgent"
    }
  })
end
