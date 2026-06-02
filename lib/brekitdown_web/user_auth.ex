defmodule BrekitdownWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Brekitdown.Accounts
  alias Brekitdown.Accounts.Scope

  @doc """
  Authenticates the user from the `Authorization: Bearer <token>` header.

  The bearer value is the Base64URL-encoded session token (the raw DB-backed
  token from `Accounts.generate_user_session_token/1`). On a valid, unexpired
  token we assign `:current_scope` with the user and stash the raw token under
  `:user_token` so logout can revoke it. A missing/malformed/expired token
  yields an anonymous scope (the request continues; route guards decide access).
  """
  def fetch_current_scope_for_user(conn, _opts) do
    with {:ok, raw_token} <- bearer_token(conn),
         {user, _token_inserted_at} <- Accounts.get_user_by_session_token(raw_token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> assign(:user_token, raw_token)
    else
      _ -> assign(conn, :current_scope, Scope.for_user(nil))
    end
  end

  defp bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> encoded] -> Base.url_decode64(encoded, padding: false)
      _ -> :error
    end
  end

  @doc """
  Plug for routes that require an authenticated user.

  Halts with `401` and a JSON error when there is no current user.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns.current_scope && conn.assigns.current_scope.user do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "unauthorized"})
      |> halt()
    end
  end
end
