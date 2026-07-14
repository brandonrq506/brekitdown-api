defmodule BrekitdownWeb.Schemas.TasksResponse do
  @moduledoc "List-of-tasks response envelope: %{data: [Task]}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Task
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TasksResponse",
    type: :object,
    properties: %{data: %Schema{type: :array, items: Task}},
    required: [:data]
  })
end
