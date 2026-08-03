defmodule BrekitdownWeb.Schemas.TimeEntryCreateRequest do
  @moduledoc """
  Request body for creating a time entry: a nested time entry object.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TimeEntryCreateRequest",
    type: :object,
    properties: %{
      time_entry: %Schema{
        type: :object,
        properties: %{
          started_at: %Schema{type: :string, format: :"date-time"},
          ended_at: %Schema{type: :string, format: :"date-time", nullable: true}
        },
        required: [:started_at]
      }
    },
    required: [:time_entry],
    example: %{
      time_entry: %{started_at: "2024-06-01T09:00:00Z"}
    }
  })
end
