defmodule BrekitdownWeb.Schemas.UserWithToken do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias BrekitdownWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UserWithToken",
    type: :object,
    properties: %{user: User, token: %Schema{type: :string}},
    required: [:user, :token]
  })
end
