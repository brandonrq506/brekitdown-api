defmodule BrekitdownWeb.Schemas.TaskNote do
  @moduledoc "Public representation of a task note (never the internal ids)."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskNote",
    description: "A note on a task as exposed by the API",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      title: %Schema{type: :string, maxLength: 100},
      body: %Schema{type: :string, maxLength: 5000},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      updated_at: %Schema{type: :string, format: :"date-time"}
    },
    required: [:reference_xid, :title, :body, :inserted_at, :updated_at],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      title: "Where I left off",
      body: "Auth middleware is done; the token refresh path still 401s on expiry.",
      inserted_at: "2024-06-30T09:00:00Z",
      updated_at: "2024-06-30T09:00:00Z"
    }
  })
end
