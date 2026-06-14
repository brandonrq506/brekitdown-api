defmodule BrekitdownWeb.UserControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  describe "GET /api/users/me" do
    setup :register_and_log_in_user

    test "returns the current user", %{conn: conn, user: user} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/users/me")

      assert %{"user" => body_user} = json_response(conn, 200)
      assert body_user["email"] == user.email
      assert body_user["reference_xid"] == user.reference_xid
      refute Map.has_key?(body_user, "id")
      refute Map.has_key?(body_user, "hashed_password")
      assert_response_schema(conn, 200, "UserResponse")
    end
  end

  describe "GET /api/users/me without a valid token" do
    test "returns 401 when no token is given", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/users/me")

      assert_response_schema(conn, 401, "Error")
    end

    test "returns 401 for a malformed token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer not-a-real-token")
        |> get(~p"/api/users/me")

      assert_response_schema(conn, 401, "Error")
    end
  end
end
