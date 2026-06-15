defmodule BrekitdownWeb.Schemas.LoginRequest do
  @moduledoc "Request body for POST /api/users/log-in: a nested user with email and password credentials."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginRequest",
    type: :object,
    properties: %{
      user: %Schema{
        type: :object,
        properties: %{
          email: %Schema{type: :string, format: :email},
          password: %Schema{type: :string}
        },
        required: [:email, :password]
      }
    },
    required: [:user]
  })
end
