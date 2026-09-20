defmodule Brekitdown.TaskNotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.TaskNotes` context.
  """

  @doc """
  Generate a task note.
  """
  def task_note_fixture(scope, task, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        title: "Note title",
        body: "Note body"
      })

    {:ok, task_note} = Brekitdown.TaskNotes.create_task_note(scope, task, attrs)
    task_note
  end
end
