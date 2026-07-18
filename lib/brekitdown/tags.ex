defmodule Brekitdown.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Brekitdown.Repo

  alias Brekitdown.Accounts.Scope
  alias Brekitdown.Tags.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags(scope)
      [%Tag{}, ...]

  """
  def list_tags(%Scope{} = scope) do
    Repo.all_by(Tag, user_id: scope.user.id)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Tag{}

      iex> get_tag!(scope, "550e8400-e29b-41d4-a716-446655440001")
      ** (Ecto.NoResultsError)

  """
  def get_tag!(%Scope{} = scope, reference_xid) do
    Repo.get_by!(Tag, reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Gets a single tag.

  Returns `nil` if the Tag does not exist.

  ## Examples

      iex> get_tag(scope, "550e8400-e29b-41d4-a716-446655440000")
      %Tag{}

      iex> get_tag(scope, "550e8400-e29b-41d4-a716-446655440001")
      nil

  """
  def get_tag(%Scope{} = scope, reference_xid) do
    Repo.get_by(Tag, reference_xid: reference_xid, user_id: scope.user.id)
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(scope, %{field: value})
      {:ok, %Tag{}}

      iex> create_tag(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(%Scope{} = scope, attrs) do
    with {:ok, tag = %Tag{}} <-
           %Tag{}
           |> Tag.create_changeset(attrs, scope)
           |> Repo.insert() do
      {:ok, tag}
    end
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(scope, tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(scope, tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Scope{} = scope, %Tag{} = tag, attrs) do
    true = tag.user_id == scope.user.id

    with {:ok, tag = %Tag{}} <-
           tag
           |> Tag.update_changeset(attrs)
           |> Repo.update() do
      {:ok, tag}
    end
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(scope, tag)
      {:ok, %Tag{}}

      iex> delete_tag(scope, tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Scope{} = scope, %Tag{} = tag) do
    true = tag.user_id == scope.user.id

    with {:ok, tag = %Tag{}} <-
           Repo.delete(tag) do
      {:ok, tag}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(scope, tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Scope{} = scope, %Tag{} = tag, attrs \\ %{}) do
    true = tag.user_id == scope.user.id

    Tag.create_changeset(tag, attrs, scope)
  end

  @doc """
  Finds a tag by name or creates it if it doesn't exist.

  ## Examples

      iex> find_or_create_tag(scope, "tag_name")
      {:ok, %Tag{}}

  """
  def find_or_create_tag(%Scope{} = scope, name) do
    normalized = Tag.normalize(name)

    case Repo.get_by(Tag, user_id: scope.user.id, name: normalized) do
      %Tag{} = tag -> {:ok, tag}
      nil -> create_tag(scope, %{name: normalized})
    end
  end
end
