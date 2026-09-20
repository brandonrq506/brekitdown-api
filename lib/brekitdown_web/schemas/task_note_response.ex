defmodule BrekitdownWeb.Schemas.TaskNoteResponse do
  @moduledoc "Task note response envelope: %{data: TaskNote}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.TaskNote

  OpenApiSpex.schema(%{
    title: "TaskNoteResponse",
    type: :object,
    properties: %{data: TaskNote},
    required: [:data]
  })
end
