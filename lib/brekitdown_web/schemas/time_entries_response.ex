defmodule BrekitdownWeb.Schemas.TimeEntriesResponse do
  @moduledoc "Time entries response envelope: %{data: [TimeEntry]}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.TimeEntry
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TimeEntriesResponse",
    type: :object,
    properties: %{data: %Schema{type: :array, items: TimeEntry}},
    required: [:data]
  })
end
