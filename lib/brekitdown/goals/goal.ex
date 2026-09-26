defmodule Brekitdown.Goals.Goal do
  use Ecto.Schema
  use Flop.Schema
  import Ecto.Changeset
  import Ecto.Query

  @page_sizes [10, 20, 30, 40, 50]

  @flop_options [
    filterable: [],
    sortable: [:starred, :name],
    adapter_opts: [
      custom_fields: [
        starred: [
          field_dynamic: {__MODULE__, :starred_dynamic, []},
          ecto_type: :boolean
        ]
      ]
    ],
    default_limit: 20,
    max_limit: 50,
    pagination_types: [:page],
    default_pagination_type: :page,
    default_order: %{
      order_by: [:starred, :name],
      order_directions: [:desc, :asc]
    }
  ]

  @derive {Phoenix.Param, key: :reference_xid}

  schema "goals" do
    field :name, :string
    field :description, :string
    field :archived_at, :utc_datetime
    field :starred_at, :utc_datetime
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :user_id, :id

    has_many :tasks, Brekitdown.Tasks.Task, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs, user_scope) do
    goal
    |> cast(attrs, [:name, :description, :archived_at, :starred_at])
    |> validate_required([:name])
    |> validate_length(:name, max: 100)
    |> put_change(:user_id, user_scope.user.id)
  end

  def page_sizes, do: @page_sizes

  def starred_dynamic(_opts), do: dynamic([goal], not is_nil(goal.starred_at))
end
