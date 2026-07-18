defmodule BrekitdownWeb.Schemas.TagResponse do
  @moduledoc "Single-tag response envelope: %{data: Tag}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.Tag

  OpenApiSpex.schema(%{
    title: "TagResponse",
    type: :object,
    properties: %{data: Tag},
    required: [:data]
  })
end
