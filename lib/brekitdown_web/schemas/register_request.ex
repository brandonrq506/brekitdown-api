defmodule BrekitdownWeb.Schemas.RegisterRequest do
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
