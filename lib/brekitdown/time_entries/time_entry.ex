defmodule Brekitdown.TimeEntries.TimeEntry do
  @moduledoc """
  One interval of work on a task. A nil `ended_at` means the timer is still running.

  - `started_at` and `ended_at` are supplied by the client — they record when the user acted.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference_xid}

  schema "time_entries" do
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :user_id, :id

    belongs_to :task, Brekitdown.Tasks.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(time_entry, attrs, user_scope, task) do
    time_entry
    |> cast(attrs, [:started_at, :ended_at])
    |> validate_required([:started_at])
    |> put_change(:user_id, user_scope.user.id)
    |> put_change(:task_id, task.id)
    |> validate_ended_not_before_started()
    |> unique_constraint(:task_id, name: :time_entries_one_open_per_task_index)
    |> check_constraint(:ended_at, name: :time_entries_ended_at_after_started_at)
  end

  @doc false
  def update_changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, [:started_at, :ended_at])
    |> validate_required([:started_at])
    |> validate_ended_not_before_started()
    |> unique_constraint(:task_id, name: :time_entries_one_open_per_task_index)
    |> check_constraint(:ended_at, name: :time_entries_ended_at_after_started_at)
  end

  @doc """
  Whether the entry is still running (`:open`) or finished (`:closed`).

  Derived from `ended_at` rather than stored, so it cannot drift from the timestamps.

  ## Examples

      iex> state(%TimeEntry{ended_at: nil})
      :open

  """
  def state(%__MODULE__{ended_at: nil}), do: :open
  def state(%__MODULE__{}), do: :closed

  defp validate_ended_not_before_started(changeset) do
    started_at = get_field(changeset, :started_at)
    ended_at = get_field(changeset, :ended_at)

    if started_at && ended_at && DateTime.before?(ended_at, started_at) do
      add_error(changeset, :ended_at, "must not be before started_at")
    else
      changeset
    end
  end
end
