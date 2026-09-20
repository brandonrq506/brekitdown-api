defmodule BrekitdownWeb.Schemas.TaskNotesResponse do
  @moduledoc "Task notes response envelope: %{data: [TaskNote]}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.TaskNote
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TaskNotesResponse",
    type: :object,
    properties: %{data: %Schema{type: :array, items: TaskNote}},
    required: [:data]
  })
end
