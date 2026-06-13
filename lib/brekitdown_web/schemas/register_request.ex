defmodule BrekitdownWeb.Schemas.RegisterRequest do
  @moduledoc "Request body for POST /api/users/register: a nested user with email and password."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RegisterRequest",
    type: :object,
    properties: %{
      user: %Schema{
        type: :object,
        properties: %{
          email: %Schema{type: :string, format: :email},
          password: %Schema{type: :string, minLength: 12, maxLength: 72}
        },
        required: [:email, :password]
      }
    },
    required: [:user]
  })
end
