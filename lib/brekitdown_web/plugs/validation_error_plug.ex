defmodule BrekitdownWeb.ValidationErrorPlug do
  @moduledoc """
  Renders OpenApiSpex request-validation failures as 422s in the same
  `%{errors: %{field => [messages]}}` shape as `BrekitdownWeb.ChangesetJSON`,
  so cast errors and changeset errors are indistinguishable to clients.
  """

  @behaviour Plug

  alias OpenApiSpex.Cast.Error

  @impl Plug
  def init(errors), do: errors

  @impl Plug
  def call(conn, errors) do
    body = Jason.encode!(%{errors: Enum.group_by(errors, &field_name/1, &Error.message/1)})

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(:unprocessable_content, body)
  end

  defp field_name(%Error{path: []}), do: "body"
  defp field_name(%Error{path: path}), do: path |> List.last() |> to_string()
end
