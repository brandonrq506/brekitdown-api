defmodule BrekitdownWeb.Schemas.TaskResponse do
  @moduledoc "Single-task response envelope: %{data: Task}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Task

  OpenApiSpex.schema(%{
    title: "TaskResponse",
    type: :object,
    properties: %{data: Task},
    required: [:data]
  })
end
