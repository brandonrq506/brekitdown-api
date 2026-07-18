defmodule BrekitdownWeb.Schemas.TaskTagCreateRequest do
  @moduledoc "Request body for attaching a tag to a task."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskTagCreateRequest",
    type: :object,
    properties: %{name: %Schema{type: :string, maxLength: 50}},
    required: [:name],
    example: %{name: "Bitesized"}
  })
end
