defmodule BrekitdownWeb.Schemas.UserResponse do
  @moduledoc "Single-user response envelope. Returned by GET /api/users/me."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UserResponse",
    type: :object,
    properties: %{user: User},
    required: [:user]
  })
end
