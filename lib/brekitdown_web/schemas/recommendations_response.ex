defmodule BrekitdownWeb.Schemas.RecommendationsResponse do
  @moduledoc "Recommended-tasks response envelope: %{data: [Task], meta: CursorPaginationMeta}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.CursorPaginationMeta
  alias BrekitdownWeb.Schemas.Task
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "RecommendationsResponse",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: Task},
      meta: CursorPaginationMeta
    },
    required: [:data, :meta]
  })
end
