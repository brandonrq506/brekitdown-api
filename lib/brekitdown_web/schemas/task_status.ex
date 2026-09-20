defmodule BrekitdownWeb.Schemas.TaskStatus do
  @moduledoc "The statuses a task can hold, derived from `Brekitdown.Tasks.TaskStatuses`."
  require OpenApiSpex

  alias Brekitdown.Tasks.TaskStatuses

  # Read at compile time, so adding a status to TaskStatuses recompiles this schema
  # instead of leaving the published spec behind. `struct?: false` because a string
  # schema has no properties to build a struct from.
  OpenApiSpex.schema(
    %{
      title: "TaskStatus",
      type: :string,
      enum: Enum.map(TaskStatuses.all(), &Atom.to_string/1)
    },
    struct?: false,
    derive?: false
  )
end
