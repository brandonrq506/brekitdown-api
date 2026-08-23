defmodule BrekitdownWeb.GoalControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.GoalsFixtures
  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]

  alias Brekitdown.Goals.Goal

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists only the current user's goals", %{conn: conn, scope: scope} do
      goal = goal_fixture(scope)
      _other_user_goal = goal_fixture(user_scope_fixture())

      conn = get(conn, ~p"/api/goals")
      body = assert_response_schema(conn, 200, "GoalsResponse")
      assert [%{"reference_xid" => ref}] = body["data"]
      assert ref == goal.reference_xid
    end

    test "returns an empty list when the user has no goals", %{conn: conn} do
      conn = get(conn, ~p"/api/goals")
      assert assert_response_schema(conn, 200, "GoalsResponse")["data"] == []
    end
  end

  describe "create goal" do
    test "renders the goal when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/goals", goal: @create_attrs)
      created = assert_response_schema(conn, 201, "GoalResponse")["data"]

      assert %{
               "reference_xid" => ref,
               "name" => "some name",
               "description" => "some description"
             } = created

      assert is_binary(created["inserted_at"])
      assert is_binary(created["updated_at"])

      # internal columns must never be exposed
      refute Map.has_key?(created, "id")
      refute Map.has_key?(created, "user_id")

      conn = get(conn, ~p"/api/goals/#{ref}")
      assert assert_response_schema(conn, 200, "GoalResponse")["data"]["reference_xid"] == ref
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/goals", goal: @invalid_attrs)
      assert %{"errors" => %{"name" => _}} = assert_response_schema(conn, 422, "ChangesetError")
    end
  end

  describe "show goal" do
    setup [:create_goal]

    test "404s for another user's goal", %{conn: conn} do
      other_goal = goal_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/goals/#{other_goal}")
      end
    end
  end

  describe "update goal" do
    setup [:create_goal]

    test "renders the goal when data is valid", %{
      conn: conn,
      goal: %Goal{reference_xid: ref} = goal
    } do
      conn = put(conn, ~p"/api/goals/#{goal}", goal: @update_attrs)

      assert %{"reference_xid" => ^ref} =
               assert_response_schema(conn, 200, "GoalResponse")["data"]

      conn = get(conn, ~p"/api/goals/#{ref}")

      assert %{
               "reference_xid" => ^ref,
               "name" => "some updated name",
               "description" => "some updated description"
             } = assert_response_schema(conn, 200, "GoalResponse")["data"]
    end

    test "updates only the description when name is omitted", %{conn: conn, goal: goal} do
      conn = put(conn, ~p"/api/goals/#{goal}", goal: %{description: "updated description"})

      assert %{
               "name" => "some name",
               "description" => "updated description"
             } = assert_response_schema(conn, 200, "GoalResponse")["data"]
    end

    test "renders errors when no update attributes are provided", %{conn: conn, goal: goal} do
      conn = put(conn, ~p"/api/goals/#{goal}", goal: %{})
      assert %{"errors" => _} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "renders errors when data is invalid", %{conn: conn, goal: goal} do
      conn = put(conn, ~p"/api/goals/#{goal}", goal: @invalid_attrs)
      assert %{"errors" => _} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404s for another user's goal", %{conn: conn} do
      other_goal = goal_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        put(conn, ~p"/api/goals/#{other_goal}", goal: @update_attrs)
      end
    end
  end

  describe "delete goal" do
    setup [:create_goal]

    test "deletes the chosen goal", %{conn: conn, goal: goal} do
      conn = delete(conn, ~p"/api/goals/#{goal}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/goals/#{goal}")
      end
    end

    test "404s for another user's goal", %{conn: conn} do
      other_goal = goal_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/goals/#{other_goal}")
      end
    end
  end

  defp create_goal(%{scope: scope}) do
    %{goal: goal_fixture(scope)}
  end
end
