defmodule BrekitdownWeb.Schemas.TagUpdateRequest do
  @moduledoc "Tag update request envelope: %{data: TagUpdateRequestData}."
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TagUpdateRequest",
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
