defmodule BrekitdownWeb.Schemas.UserResponse do
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UserResponse",
    type: :object,
    properties: %{user: User},
    required: [:user]
  })
end
