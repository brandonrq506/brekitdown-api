defmodule Brekitdown.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Brekitdown.Tasks.TaskStatuses

  @derive {Phoenix.Param, key: :reference_xid}

  schema "tasks" do
    field :name, :string

    field :status, Ecto.Enum,
      values: TaskStatuses.all(),
      default: TaskStatuses.default()

    field :due_at, :utc_datetime
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :user_id, :id

    belongs_to :goal, Brekitdown.Goals.Goal
    belongs_to :parent, Brekitdown.Tasks.Task

    has_many :time_entries, Brekitdown.TimeEntries.TimeEntry
    has_many :subtasks, Brekitdown.Tasks.Task, foreign_key: :parent_id

    many_to_many :tags, Brekitdown.Tags.Tag, join_through: Brekitdown.Tags.TaskTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(task, attrs, user_scope) do
    task
    |> cast(attrs, [:name, :status, :due_at])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> put_change(:user_id, user_scope.user.id)
  end

  @doc false
  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :due_at])
    |> validate_length(:name, max: 100)
    |> validate_required([:name])
  end
end
