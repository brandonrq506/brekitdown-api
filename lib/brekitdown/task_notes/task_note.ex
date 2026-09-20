defmodule Brekitdown.TaskNotes.TaskNote do
  @moduledoc """
  A piece of prose attached to a task. A task may hold any number of notes.

  Chronological, not definitional — `tasks.description` answers "what is this task",
  a note answers "what happened while I worked on it".
  """

  use Ecto.Schema

  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference_xid}

  @title_max 100
  @body_max 5000

  schema "task_notes" do
    field :title, :string, default: ""
    field :body, :string, default: ""
    field :reference_xid, Ecto.UUID, read_after_writes: true

    belongs_to :task, Brekitdown.Tasks.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(task_note, attrs, task) do
    task_note
    |> cast(attrs, [:title, :body])
    |> trim_prose()
    |> validate_required([:title, :body])
    |> validate_length(:title, max: @title_max)
    |> validate_length(:body, max: @body_max)
    |> put_change(:task_id, task.id)
  end

  @doc false
  def update_changeset(task_note, attrs) do
    task_note
    |> cast(attrs, [:title, :body])
    |> trim_prose()
    |> validate_required([:title, :body])
    |> validate_length(:title, max: @title_max)
    |> validate_length(:body, max: @body_max)
  end

  defp trim_prose(changeset) do
    changeset
    |> update_change(:title, &trim/1)
    |> update_change(:body, &trim/1)
  end

  defp trim(value) when is_binary(value), do: String.trim(value)
  defp trim(nil), do: nil
end
