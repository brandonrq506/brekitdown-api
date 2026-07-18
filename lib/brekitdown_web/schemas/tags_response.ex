defmodule BrekitdownWeb.Schemas.TagsResponse do
  @moduledoc "List-of-tags response envelope: %{data: [Tag]}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Tag
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TagsResponse",
    type: :object,
    properties: %{data: %Schema{type: :array, items: Tag}},
    required: [:data]
  })
end
