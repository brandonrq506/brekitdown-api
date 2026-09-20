defmodule BrekitdownWeb.Schemas.TaskNoteUpdateRequest do
  @moduledoc """
  Request body for updating a task note: a nested note object.

  Neither key is required here, so a client may send `body` alone. The record still ends up
  with both — `update_changeset/2` validates against `get_field/2`, which falls back to the
  stored value for whatever the request left out.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskNoteUpdateRequest",
    type: :object,
    properties: %{
      note: %Schema{
        type: :object,
        properties: %{
          title: %Schema{type: :string, maxLength: 100},
          body: %Schema{type: :string, maxLength: 5000}
        },
        minProperties: 1,
        additionalProperties: false
      }
    },
    required: [:note],
    example: %{
      note: %{body: "Fixed it: the refresh token was being compared before trimming."}
    }
  })
end
