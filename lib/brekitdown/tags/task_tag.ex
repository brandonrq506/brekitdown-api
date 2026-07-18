defmodule Brekitdown.Tags.TaskTag do
  use Ecto.Schema

  @primary_key false
  schema "tasks_tags" do
    belongs_to :task, Brekitdown.Tasks.Task, primary_key: true
    belongs_to :tag, Brekitdown.Tags.Tag, primary_key: true

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
