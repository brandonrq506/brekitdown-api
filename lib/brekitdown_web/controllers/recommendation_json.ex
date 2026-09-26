defmodule BrekitdownWeb.RecommendationJSON do
  alias BrekitdownWeb.{PaginationJSON, TaskJSON}

  def index(%{tasks: tasks, flop_meta: flop_meta}) do
    %{
      data: for(task <- tasks, do: TaskJSON.data(task)),
      meta: PaginationJSON.cursor_meta(flop_meta)
    }
  end
end
