defmodule BrekitdownWeb.Schemas.TimeEntryUpdateRequest do
  @moduledoc """
  Request body for updating a time entry: a nested time entry object.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TimeEntryUpdateRequest",
    type: :object,
    properties: %{
      time_entry: %Schema{
        type: :object,
        properties: %{
          started_at: %Schema{type: :string, format: :"date-time"},
          ended_at: %Schema{type: :string, format: :"date-time", nullable: true}
        }
      }
    },
    required: [:time_entry],
    example: %{
      time_entry: %{ended_at: "2024-06-01T10:00:00Z"}
    }
  })
end
