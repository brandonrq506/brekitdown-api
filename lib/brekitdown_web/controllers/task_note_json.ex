defmodule BrekitdownWeb.TaskNoteJSON do
  alias Brekitdown.TaskNotes.TaskNote

  @doc "Renders a list of task notes."
  def index(%{task_notes: task_notes}) do
    %{data: for(task_note <- task_notes, do: data(task_note))}
  end

  @doc "Renders a single task note."
  def show(%{task_note: task_note}) do
    %{data: data(task_note)}
  end

  defp data(%TaskNote{} = task_note) do
    %{
      reference_xid: task_note.reference_xid,
      title: task_note.title,
      body: task_note.body,
      inserted_at: task_note.inserted_at,
      updated_at: task_note.updated_at
    }
  end
end
