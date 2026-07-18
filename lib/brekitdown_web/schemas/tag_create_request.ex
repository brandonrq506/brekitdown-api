defmodule BrekitdownWeb.Schemas.TagCreateRequest do
  @moduledoc "Tag creation request envelope: %{data: TagCreateRequestData}."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TagCreateRequest",
    type: :object,
    properties: %{
      tag: %Schema{
        type: :object,
        properties: %{
          name: %Schema{type: :string, maxLength: 50}
        },
        required: [:name]
      }
    },
    required: [:tag]
  })
end
