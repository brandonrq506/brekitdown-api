defmodule BrekitdownWeb.Schemas.PaginationMeta do
  @moduledoc "OpenAPI schema for page-based pagination metadata."

  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "PaginationMeta",
    description: "Metadata for paginated responses",
    type: :object,
    properties: %{
      current_page: %Schema{type: :integer, minimum: 1, description: "Current page number"},
      page_size: %Schema{type: :integer, minimum: 1, description: "Number of items per page"},
      total_count: %Schema{type: :integer, minimum: 0, description: "Total number of items"},
      total_pages: %Schema{type: :integer, minimum: 0, description: "Total number of pages"},
      has_next_page: %Schema{type: :boolean, description: "Whether there is a next page"},
      has_previous_page: %Schema{type: :boolean, description: "Whether there is a previous page"},
      next_page: %Schema{
        type: :integer,
        minimum: 1,
        nullable: true,
        description: "Next page number, if any"
      },
      previous_page: %Schema{
        type: :integer,
        minimum: 1,
        nullable: true,
        description: "Previous page number, if any"
      }
    },
    required: [
      :current_page,
      :page_size,
      :total_count,
      :total_pages,
      :has_next_page,
      :has_previous_page,
      :next_page,
      :previous_page
    ]
  })
end
