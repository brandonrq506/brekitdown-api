defmodule BrekitdownWeb.Schemas.CursorPaginationMeta do
  @moduledoc "OpenAPI schema for cursor-based pagination metadata (Flop first/after)."

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CursorPaginationMeta",
    description: "Metadata for cursor-paginated responses",
    type: :object,
    properties: %{
      page_size: %Schema{type: :integer, minimum: 1, description: "Number of items per page"},
      has_next_page: %Schema{type: :boolean, description: "Whether there is a next page"},
      end_cursor: %Schema{
        type: :string,
        nullable: true,
        description: "Opaque cursor of the last item; pass as `after` to fetch the next page"
      }
    },
    required: [:page_size, :has_next_page, :end_cursor]
  })
end
