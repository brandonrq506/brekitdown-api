defmodule Brekitdown.Tasks.TaskStatuses do
  @moduledoc """
  Module for managing task statuses.
  """

  @all [:scheduled, :in_progress, :completed, :dropped, :on_hold]
  @default :scheduled
  @recommendable [:scheduled, :in_progress]

  @doc """
  Returns all valid task statuses.
  """
  def all, do: @all

  @doc """
  Returns the default task status.
  """
  def default, do: @default

  @doc "Statuses eligible for the recommendation list."
  def recommendable, do: @recommendable

  @doc """
  Asserts a term is a valid task status.

  ## Examples

      iex> is_task_status(:in_progress)
      true

  """
  defguard is_task_status(status) when status in @all
end
