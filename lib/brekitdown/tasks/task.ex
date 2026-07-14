defmodule Brekitdown.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference_xid}

  schema "tasks" do
    field :name, :string

    field :status, Ecto.Enum,
      values: [:scheduled, :in_progress, :completed, :dropped, :on_hold],
      default: :scheduled

    field :due_at, :utc_datetime
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :parent_id, :id
    field :user_id, :id

    belongs_to :goal, Brekitdown.Goals.Goal

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
