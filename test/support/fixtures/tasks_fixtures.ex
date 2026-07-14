defmodule Brekitdown.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Task 1",
        status: :scheduled,
        due_at: DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second)
      })

    {:ok, task} = Brekitdown.Tasks.create_task(scope, attrs)
    task
  end
end
