defmodule BrekitdownWeb.PaginationJSON do
  @doc """
  Returns pagination metadata for a given Flop.Meta struct.
  """
  def pagination_meta(%Flop.Meta{} = meta) do
    %{
      current_page: meta.current_page,
      page_size: meta.page_size,
      total_count: meta.total_count,
      total_pages: meta.total_pages,
      has_next_page: meta.has_next_page?,
      has_previous_page: meta.has_previous_page?,
      next_page: meta.next_page,
      previous_page: meta.previous_page
    }
  end

  @doc "Cursor pagination metadata (Flop :first/:after)."
  def cursor_meta(%Flop.Meta{} = meta) do
    %{
      page_size: meta.page_size,
      has_next_page: meta.has_next_page?,
      # nil on an empty page
      end_cursor: meta.end_cursor
    }
  end
end
