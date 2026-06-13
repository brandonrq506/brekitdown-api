defmodule BrekitdownWeb.Schemas.ChangesetError do
  @moduledoc "Validation error envelope keyed by field name (field => list of messages). Returned as 422 on register."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ChangesetError",
    description: "Validation errors keyed by field name",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        additionalProperties: %Schema{
          type: :array,
          items: %Schema{type: :string}
        }
      }
    },
    required: [:errors],
    example: %{
      errors: %{
        email: ["has already been taken"],
        password: ["should be at least 12 characters"]
      }
    }
  })
end
