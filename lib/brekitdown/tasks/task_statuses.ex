defmodule Brekitdown.Tasks.TaskStatuses do
  @moduledoc """
  Module for managing task statuses.
  """

  @all [:scheduled, :in_progress, :completed, :dropped, :on_hold]
  @default :scheduled
  @recommendable [:scheduled, :in_progress]
  @open [:scheduled, :in_progress, :on_hold]
  @closed [:completed, :dropped]

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

  @doc "Statuses of an Open task."
  def open, do: @open

  @doc "Statuses of a Closed task."
  def closed, do: @closed

  @doc """
  Asserts a term is an Open task status.

  ## Examples

      iex> is_open_status(:on_hold)
      true

  """
  defguard is_open_status(status) when status in @open

  @doc """
  Asserts a term is a Closed task status.

  ## Examples

      iex> is_closed_status(:completed)
      true

  """
  defguard is_closed_status(status) when status in @closed

  @doc """
  Asserts a term is a valid task status.

  ## Examples

      iex> is_task_status(:in_progress)
      true

  """
  defguard is_task_status(status) when status in @all
end
