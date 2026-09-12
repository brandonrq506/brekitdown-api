defmodule BrekitdownWeb.TaskJSON do
  alias Brekitdown.Goals.Goal
  alias Brekitdown.Tags.Tag
  alias Brekitdown.Tasks.Task
  alias Brekitdown.TimeEntries.TimeEntry

  @doc "Renders a list of tasks."
  def index(%{tasks: tasks}) do
    %{data: for(task <- tasks, do: data(task))}
  end

  @doc "Renders a single task."
  def show(%{task: task}) do
    %{data: data(task)}
  end

  defp data(%Task{} = task) do
    %{
      reference_xid: task.reference_xid,
      name: task.name,
      description: task.description,
      status: task.status,
      due_at: task.due_at,
      goal_reference_xid: goal_reference_xid(task.goal),
      parent_reference_xid: parent_reference_xid(task.parent),
      has_children: task.has_children,
      tags: tags(task.tags),
      time_entries: time_entries(task.time_entries),
      inserted_at: task.inserted_at,
      updated_at: task.updated_at
    }
  end

  defp goal_reference_xid(%Goal{reference_xid: ref}), do: ref
  defp goal_reference_xid(_), do: nil

  defp parent_reference_xid(%Task{reference_xid: ref}), do: ref
  defp parent_reference_xid(_), do: nil

  defp tags(tags) when is_list(tags) do
    for %Tag{} = tag <- tags do
      %{
        reference_xid: tag.reference_xid,
        name: tag.name,
        inserted_at: tag.inserted_at,
        updated_at: tag.updated_at
      }
    end
  end

  defp tags(_), do: []

  defp time_entries(time_entries) when is_list(time_entries) do
    for %TimeEntry{} = time_entry <- time_entries do
      %{
        reference_xid: time_entry.reference_xid,
        started_at: time_entry.started_at,
        ended_at: time_entry.ended_at,
        inserted_at: time_entry.inserted_at,
        updated_at: time_entry.updated_at
      }
    end
  end

  defp time_entries(_), do: []
end
