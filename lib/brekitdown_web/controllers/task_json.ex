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
      tags: tags(task.tags)
    }
  end

  defp goal_reference_xid(%Goal{reference_xid: ref}), do: ref
  defp goal_reference_xid(_), do: nil

  defp tags(tags) when is_list(tags) do
    for %Tag{} = tag <- tags do
      %{reference_xid: tag.reference_xid, name: tag.name}
    end
  end

  defp tags(_), do: []
end
