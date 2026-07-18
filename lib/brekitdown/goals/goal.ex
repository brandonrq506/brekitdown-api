defmodule Brekitdown.Goals.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference_xid}

  schema "goals" do
    field :name, :string
    field :description, :string
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :user_id, :id

    has_many :tasks, Brekitdown.Tasks.Task, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs, user_scope) do
    goal
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> put_change(:user_id, user_scope.user.id)
  end
end
