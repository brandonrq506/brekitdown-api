defmodule BrekitdownWeb.Schemas.GoalFilters do
  @moduledoc "Index-keyed map of GoalFilter, as Plug decodes `filters[0][...]=`."
  require OpenApiSpex
  alias BrekitdownWeb.Schemas.GoalFilter

  OpenApiSpex.schema(
    %{
      title: "GoalFilters",
      description:
        "Filters keyed by zero-based index, e.g. " <>
          "`?filters[0][field]=completed&filters[0][op]=%3D%3D&filters[0][value]=false`. " <>
          "No filter returns every goal.",
      type: :object,
      additionalProperties: GoalFilter,
      example: %{"0" => %{field: "completed", op: "==", value: false}}
    },
    struct?: false
  )
end
