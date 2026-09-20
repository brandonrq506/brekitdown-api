defmodule BrekitdownWeb.Schemas.TaskNoteCreateRequest do
  @moduledoc """
  Request body for creating a task note: a nested note object.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskNoteCreateRequest",
    type: :object,
    properties: %{
      note: %Schema{
        type: :object,
        properties: %{
          title: %Schema{type: :string, maxLength: 100},
          body: %Schema{type: :string, maxLength: 5000}
        },
        required: [:title, :body]
      }
    },
    required: [:note],
    example: %{
      note: %{title: "Where I left off", body: "The token refresh path still 401s on expiry."}
    }
  })
end
