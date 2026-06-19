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
      description: %Schema{type: :string, nullable: true}
    },
    required: [:reference_xid, :name],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      name: "Learn to use Claude",
      description: "Become more valuable and efficient at work"
    }
  })
end
