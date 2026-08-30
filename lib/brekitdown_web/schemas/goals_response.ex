defmodule BrekitdownWeb.Schemas.GoalsResponse do
  @moduledoc "List-of-goals response envelope: %{data: [Goal]}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Goal
  alias BrekitdownWeb.Schemas.PaginationMeta
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "GoalsResponse",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: Goal},
      meta: PaginationMeta
    },
    required: [:data, :meta]
  })
end
