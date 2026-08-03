defmodule BrekitdownWeb.Schemas.TimeEntryResponse do
  @moduledoc "Time entry response envelope: %{data: TimeEntry}."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.TimeEntry

  OpenApiSpex.schema(%{
    title: "TimeEntryResponse",
    type: :object,
    properties: %{data: TimeEntry},
    required: [:data]
  })
end
