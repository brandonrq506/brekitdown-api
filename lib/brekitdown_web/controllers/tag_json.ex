defmodule BrekitdownWeb.TagJSON do
  alias Brekitdown.Tags.Tag

  @doc """
  Renders a list of tags.
  """
  def index(%{tags: tags}) do
    %{data: for(tag <- tags, do: data(tag))}
  end

  @doc """
  Renders a single tag.
  """
  def show(%{tag: tag}) do
    %{data: data(tag)}
  end

  defp data(%Tag{} = tag) do
    %{
      reference_xid: tag.reference_xid,
      name: tag.name
    }
  end
end
