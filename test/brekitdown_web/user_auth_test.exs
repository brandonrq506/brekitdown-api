defmodule BrekitdownWeb.UserAuthTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures

  alias Brekitdown.Accounts
  alias Brekitdown.Accounts.{Scope, UserToken}
  alias Brekitdown.Repo
  alias BrekitdownWeb.UserAuth

  defp bearer(raw), do: "Bearer " <> Base.url_encode64(raw, padding: false)

  setup do
    %{user: user_fixture()}
  end

  describe "fetch_current_scope_for_user/2" do
    test "assigns the scope and stashes the raw token for a valid bearer token",
         %{conn: conn, user: user} do
      raw = Accounts.generate_user_session_token(user)

      conn =
        conn
        |> put_req_header("authorization", bearer(raw))
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope.user.id == user.id
      assert conn.assigns.user_token == raw
    end

    test "assigns an anonymous scope when no authorization header is present", %{conn: conn} do
      conn = UserAuth.fetch_current_scope_for_user(conn, [])

      assert conn.assigns.current_scope == nil
      refute Map.has_key?(conn.assigns, :user_token)
    end

    test "assigns an anonymous scope for a non-bearer scheme", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Basic abc123")
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope == nil
    end

    test "assigns an anonymous scope for a malformed token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer not-valid-base64-url!!")
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope == nil
    end

    test "assigns an anonymous scope for an expired token", %{conn: conn, user: user} do
      raw = Accounts.generate_user_session_token(user)
      old = ~N[2020-01-01 00:00:00]
      Repo.update_all(UserToken, set: [inserted_at: old, authenticated_at: old])

      conn =
        conn
        |> put_req_header("authorization", bearer(raw))
        |> UserAuth.fetch_current_scope_for_user([])

      assert conn.assigns.current_scope == nil
    end
  end

  describe "require_authenticated_user/2" do
    test "halts with a 401 JSON error when there is no authenticated user", %{conn: conn} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(nil))
        |> UserAuth.require_authenticated_user([])

      assert conn.halted
      assert conn.status == 401
      assert Jason.decode!(conn.resp_body) == %{"error" => "unauthorized"}
    end

    test "lets the request through for an authenticated user", %{conn: conn, user: user} do
      conn =
        conn
        |> assign(:current_scope, Scope.for_user(user))
        |> UserAuth.require_authenticated_user([])

      refute conn.halted
    end
  end
end
