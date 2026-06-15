defmodule BrekitdownWeb.UserRegistrationControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "POST /api/users/register" do
    test "registers a user and returns a token that authenticates them", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/api/users/register",
          user: %{email: email, password: valid_user_password()}
        )

      assert %{"user" => user, "token" => token} = json_response(conn, 201)
      assert user["email"] == email
      assert user["reference_xid"]
      # internal id and the password hash must never be exposed
      refute Map.has_key?(user, "id")
      refute Map.has_key?(user, "hashed_password")
      assert_response_schema(conn, 201, "UserWithToken")

      me =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/users/me")

      assert json_response(me, 200)["user"]["email"] == email
    end

    test "returns 422 for a schema-invalid body", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/register",
          user: %{email: unique_user_email(), password: "short"}
        )

      assert %{"errors" => %{"password" => _}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "returns 422 when the email is already taken", %{conn: conn} do
      %{email: email} = user_fixture()

      conn =
        post(conn, ~p"/api/users/register",
          user: %{email: email, password: valid_user_password()}
        )

      body = assert_response_schema(conn, 422, "ChangesetError")
      assert "has already been taken" in body["errors"]["email"]
    end
  end
end
