defmodule BrekitdownWeb.Schemas.Error do
  @moduledoc "Generic error envelope ({errors: {detail}}). Used for 4xx responses such as 401 Unauthorized."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Error",
    description: "An error response",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        properties: %{detail: %Schema{type: :string}},
        required: [:detail]
      }
    },
    required: [:errors],
    example: %{
      errors: %{
        detail: "Unauthorized"
      }
    }
  })
end
