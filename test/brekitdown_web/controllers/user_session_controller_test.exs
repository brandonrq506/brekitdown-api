defmodule BrekitdownWeb.UserSessionControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures

  alias Brekitdown.Accounts

  setup %{conn: conn} do
    %{conn: put_req_header(conn, "accept", "application/json"), user: user_fixture()}
  end

  describe "POST /api/users/log-in" do
    test "returns a token and the user for valid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/log-in",
          user: %{email: user.email, password: valid_user_password()}
        )

      assert %{"user" => body_user, "token" => token} = json_response(conn, 200)
      assert body_user["email"] == user.email
      assert is_binary(token)
    end

    test "returns 401 for an invalid password", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/api/users/log-in", user: %{email: user.email, password: "wrong password"})

      assert json_response(conn, 401) == %{"errors" => %{"detail" => "Invalid email or password"}}
    end

    test "returns 401 for an unknown email", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/log-in",
          user: %{email: "nobody@example.com", password: valid_user_password()}
        )

      assert json_response(conn, 401) == %{"errors" => %{"detail" => "Invalid email or password"}}
    end
  end

  describe "DELETE /api/users/log-out" do
    test "revokes the current token", %{user: user} do
      bearer =
        "Bearer " <> Base.url_encode64(Accounts.generate_user_session_token(user), padding: false)

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", bearer)
        |> delete(~p"/api/users/log-out")

      assert response(conn, 204)

      reused =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", bearer)
        |> get(~p"/api/users/me")

      assert json_response(reused, 401)
    end

    test "requires authentication", %{conn: conn} do
      conn = delete(conn, ~p"/api/users/log-out")
      assert json_response(conn, 401)
    end
  end
end
