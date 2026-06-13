defmodule BrekitdownWeb.Schemas.UserWithToken do
  @moduledoc "Auth success payload: a user plus the bearer token to send on subsequent requests. Returned by register and log-in."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.User
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UserWithToken",
    type: :object,
    properties: %{user: User, token: %Schema{type: :string}},
    required: [:user, :token]
  })
end
