defmodule Brekitdown.TagsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.Tags` context.
  """

  @doc """
  Generate a tag.
  """
  def tag_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name"
      })

    {:ok, tag} = Brekitdown.Tags.create_tag(scope, attrs)
    tag
  end
end
