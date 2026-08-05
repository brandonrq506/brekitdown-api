defmodule BrekitdownWeb.Schemas.ConflictError do
  @moduledoc "409 envelope: a self-sufficient `detail` explanation plus a stable `code`."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ConflictError",
    description: "The target resource's current state forbids the operation",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        properties: %{
          code: %Schema{
            type: :string,
            description: "Stable snake_case identifier, for consumers that map to their own copy"
          },
          detail: %Schema{
            type: :string,
            description: "Complete explanation of the conflict; safe to display verbatim"
          }
        },
        required: [:code, :detail]
      }
    },
    required: [:errors],
    example: %{
      errors: %{
        code: "entry_already_running",
        detail:
          "This task already has a time entry that has not ended. " <>
            "Stop it before starting or resuming another."
      }
    }
  })
end
