defmodule Brekitdown.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :reference_xid}

  schema "tags" do
    field :name, :string
    field :reference_xid, Ecto.UUID, read_after_writes: true
    field :user_id, :id

    many_to_many :tasks, Brekitdown.Tasks.Task, join_through: Brekitdown.Tags.TaskTag

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(tag, attrs, user_scope) do
    tag
    |> cast(attrs, [:name])
    |> update_change(:name, &normalize/1)
    |> validate_required([:name])
    |> validate_length(:name, max: 50)
    |> put_change(:user_id, user_scope.user.id)
    |> unsafe_validate_unique([:user_id, :name], Brekitdown.Repo, error_key: :name)
    |> unique_constraint(:name, name: :tags_user_id_name_index)
  end

  @doc false
  def update_changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> update_change(:name, &normalize/1)
    |> validate_required([:name])
    |> validate_length(:name, max: 50)
    |> unsafe_validate_unique([:user_id, :name], Brekitdown.Repo, error_key: :name)
    |> unique_constraint(:name, name: :tags_user_id_name_index)
  end

  def normalize(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  def normalize(name), do: name
end
