defmodule BrekitdownWeb.UserRegistrationControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
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

      me =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)
        |> get(~p"/api/users/me")

      assert json_response(me, 200)["user"]["email"] == email
    end

    test "returns 422 with field errors for invalid params", %{conn: conn} do
      conn =
        post(conn, ~p"/api/users/register", user: %{email: "not valid", password: "short"})

      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors["email"]
      assert errors["password"]
    end

    test "returns 422 when the email is already taken", %{conn: conn} do
      %{email: email} = user_fixture()

      conn =
        post(conn, ~p"/api/users/register",
          user: %{email: email, password: valid_user_password()}
        )

      assert "has already been taken" in json_response(conn, 422)["errors"]["email"]
    end
  end
end
