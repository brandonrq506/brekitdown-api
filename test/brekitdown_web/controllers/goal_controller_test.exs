defmodule BrekitdownWeb.GoalControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.GoalsFixtures
  import Brekitdown.TasksFixtures, only: [task_fixture: 2]
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

    test "accepts a configured page size", %{conn: conn} do
      conn = get(conn, ~p"/api/goals?page_size=10")

      assert %{"meta" => %{"page_size" => 10}} =
               assert_response_schema(conn, 200, "GoalsResponse")
    end

    test "lists starred goals first and alphabetizes each group", %{conn: conn, scope: scope} do
      goal_fixture(scope, %{name: "Zebra"})
      goal_fixture(scope, %{name: "Yarrow", starred_at: ~U[2026-09-13 12:00:00Z]})
      goal_fixture(scope, %{name: "Apple"})
      goal_fixture(scope, %{name: "Birch", starred_at: ~U[2026-09-13 11:00:00Z]})

      conn = get(conn, ~p"/api/goals")

      assert Enum.map(assert_response_schema(conn, 200, "GoalsResponse")["data"], & &1["name"]) ==
               ["Birch", "Yarrow", "Apple", "Zebra"]
    end

    test "rejects a page size outside the configured choices", %{conn: conn} do
      conn = get(conn, ~p"/api/goals?page_size=15")

      assert %{"errors" => %{"page_size" => [_message]}} =
               assert_response_schema(conn, 422, "ChangesetError")
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
      assert is_nil(created["archived_at"])
      assert is_nil(created["starred_at"])

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

    test "sets and clears the goal organization timestamps", %{conn: conn, goal: goal} do
      timestamp = "2026-09-13T12:00:00Z"

      conn =
        put(conn, ~p"/api/goals/#{goal}", goal: %{archived_at: timestamp, starred_at: timestamp})

      assert %{
               "archived_at" => ^timestamp,
               "starred_at" => ^timestamp
             } = assert_response_schema(conn, 200, "GoalResponse")["data"]

      conn =
        conn
        |> recycle()
        |> put_req_header("content-type", "application/json")
        |> put(~p"/api/goals/#{goal}",
          goal: %{archived_at: nil, starred_at: nil}
        )

      assert %{
               "archived_at" => nil,
               "starred_at" => nil
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

  describe "complete goal" do
    setup [:create_goal]

    test "sets completed_at and returns the goal", %{conn: conn, goal: goal} do
      assert goal.completed_at == nil

      conn = post(conn, ~p"/api/goals/#{goal}/complete")
      data = assert_response_schema(conn, 200, "GoalResponse")["data"]

      assert data["reference_xid"] == goal.reference_xid
      assert is_binary(data["completed_at"])
      assert data["archived_at"] == nil
    end

    test "is idempotent: the original completed_at is kept", %{conn: conn, goal: goal} do
      first = post(conn, ~p"/api/goals/#{goal}/complete")
      first_body = assert_response_schema(first, 200, "GoalResponse")

      second = post(conn, ~p"/api/goals/#{goal}/complete")
      second_body = assert_response_schema(second, 200, "GoalResponse")

      assert second_body["data"]["completed_at"] == first_body["data"]["completed_at"]
      assert second_body == first_body
    end

    test "drops open tasks, subtasks included, and leaves closed tasks untouched", %{
      conn: conn,
      scope: scope,
      goal: goal
    } do
      in_goal = %{goal_reference_xid: goal.reference_xid}
      scheduled = task_fixture(scope, in_goal)
      in_progress = task_fixture(scope, Map.put(in_goal, :status, :in_progress))
      on_hold = task_fixture(scope, Map.put(in_goal, :status, :on_hold))
      subtask = task_fixture(scope, %{parent_reference_xid: scheduled.reference_xid})
      completed = task_fixture(scope, Map.put(in_goal, :status, :completed))
      dropped = task_fixture(scope, Map.put(in_goal, :status, :dropped))

      conn = post(conn, ~p"/api/goals/#{goal}/complete")
      assert assert_response_schema(conn, 200, "GoalResponse")["data"]["completed_at"]

      statuses =
        for task <- [scheduled, in_progress, on_hold, subtask, completed, dropped] do
          conn
          |> recycle()
          |> put_req_header("accept", "application/json")
          |> get(~p"/api/tasks/#{task}")
          |> json_response(200)
          |> get_in(["data", "status"])
        end

      assert statuses == ~w(dropped dropped dropped dropped completed dropped)
    end

    test "completes a goal with zero tasks", %{conn: conn, goal: goal} do
      conn = post(conn, ~p"/api/goals/#{goal}/complete")
      assert assert_response_schema(conn, 200, "GoalResponse")["data"]["completed_at"]
    end

    test "completed_at sent through update is rejected and nothing changes", %{
      conn: conn,
      goal: goal
    } do
      conn =
        put(conn, ~p"/api/goals/#{goal}",
          goal: %{name: "renamed", completed_at: "2026-01-01T00:00:00Z"}
        )

      assert json_response(conn, 422)

      assert %{"name" => "some name", "completed_at" => nil} =
               conn
               |> recycle()
               |> put_req_header("accept", "application/json")
               |> get(~p"/api/goals/#{goal}")
               |> json_response(200)
               |> Map.fetch!("data")
    end

    test "404s for another user's goal", %{conn: conn} do
      other_goal = goal_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/goals/#{other_goal}/complete")
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
