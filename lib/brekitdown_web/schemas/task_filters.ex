defmodule BrekitdownWeb.Schemas.TaskFilters do
  @moduledoc "Index-keyed map of TaskFilter, as Plug decodes `filters[0][...]=`."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.TaskFilter

  OpenApiSpex.schema(
    %{
      title: "TaskFilters",
      description:
        "Filters keyed by zero-based index, e.g. " <>
          "`?filters[0][field]=goal_reference_xid&filters[0][op]=%3D%3D&filters[0][value]=<uuid>`.",
      type: :object,
      additionalProperties: TaskFilter,
      example: %{
        "0" => %{
          field: "goal_reference_xid",
          op: "==",
          value: "123e4567-e89b-12d3-a456-426614174001"
        }
      }
    },
    struct?: false
  )
end
