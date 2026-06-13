defmodule BrekitdownWeb.Schemas.User do
  @moduledoc "Public representation of a user, embedded in UserResponse and UserWithToken. Omits internal fields like id and hashed_password."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "User",
    description: "A user as exposed by the API (never id or hashed_password)",
    type: :object,
    properties: %{
      reference_xid: %Schema{type: :string, format: :uuid},
      email: %Schema{type: :string, format: :email},
      inserted_at: %Schema{type: :string, format: :"date-time"},
      confirmed_at: %Schema{type: :string, format: :"date-time", nullable: true}
    },
    required: [:reference_xid, :email, :inserted_at, :confirmed_at],
    example: %{
      reference_xid: "123e4567-e89b-12d3-a456-426614174000",
      email: "user@example.com",
      inserted_at: "2024-01-01T12:00:00Z",
      confirmed_at: nil
    }
  })
end
