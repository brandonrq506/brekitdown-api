defmodule BrekitdownWeb.TaskJSON do
  alias Brekitdown.Goals.Goal
  alias Brekitdown.Tags.Tag
  alias Brekitdown.Tasks.Task

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
      status: task.status,
      due_at: task.due_at,
      goal_reference_xid: goal_reference_xid(task.goal),
      parent_reference_xid: parent_reference_xid(task.parent),
      tags: tags(task.tags),
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
end
