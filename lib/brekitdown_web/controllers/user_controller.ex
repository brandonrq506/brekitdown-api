defmodule BrekitdownWeb.UserController do
  use BrekitdownWeb, :controller

  def me(conn, _params) do
    conn
    |> put_view(json: BrekitdownWeb.UserJSON)
    |> render(:user, user: conn.assigns.current_scope.user)
  end
end
