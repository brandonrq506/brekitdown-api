defmodule Brekitdown.Goals.Goal do
  use Ecto.Schema
  import Ecto.Changeset

  @page_sizes [10, 20, 30, 40, 50]

  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:name],
    default_limit: 20,
    max_limit: 50,
    pagination_types: [:page],
    default_pagination_type: :page,
    default_order: %{
      order_by: [:name],
      order_directions: [:asc]
    }
  }

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

  def page_sizes, do: @page_sizes
end
