defmodule BrekitdownWeb.TaskControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.TasksFixtures
  import Brekitdown.GoalsFixtures
  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]

  alias Brekitdown.Tasks.Task

  @create_attrs %{name: "Write tests", status: "in_progress"}
  @update_attrs %{name: "Write more tests"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "index" do
    test "lists only the current user's tasks", %{conn: conn, scope: scope} do
      task = task_fixture(scope)
      _other = task_fixture(user_scope_fixture())

      conn = get(conn, ~p"/api/tasks")
      body = assert_response_schema(conn, 200, "TasksResponse")
      assert [%{"reference_xid" => ref}] = body["data"]
      assert ref == task.reference_xid
    end

    test "returns an empty list when the user has no tasks", %{conn: conn} do
      conn = get(conn, ~p"/api/tasks")
      assert assert_response_schema(conn, 200, "TasksResponse")["data"] == []
    end
  end

  describe "create task" do
    test "renders the task when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @create_attrs)
      created = assert_response_schema(conn, 201, "TaskResponse")["data"]

      assert %{
               "reference_xid" => ref,
               "name" => "Write tests",
               "status" => "in_progress",
               "goal_reference_xid" => nil,
               "parent_reference_xid" => nil
             } = created

      # internal columns must never leak
      refute Map.has_key?(created, "id")
      refute Map.has_key?(created, "user_id")
      refute Map.has_key?(created, "goal_id")
      refute Map.has_key?(created, "parent_id")

      conn = get(conn, ~p"/api/tasks/#{ref}")
      assert assert_response_schema(conn, 200, "TaskResponse")["data"]["reference_xid"] == ref
    end

    test "attaches a goal by goal_reference_xid", %{conn: conn, scope: scope} do
      goal = goal_fixture(scope)

      conn =
        post(conn, ~p"/api/tasks", task: %{name: "x", goal_reference_xid: goal.reference_xid})

      created = assert_response_schema(conn, 201, "TaskResponse")["data"]
      assert created["goal_reference_xid"] == goal.reference_xid
    end

    test "renders an error when the name is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @invalid_attrs)
      assert %{"errors" => %{"name" => _}} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "renders a field error for an unknown goal_reference_xid", %{conn: conn} do
      conn =
        post(conn, ~p"/api/tasks", task: %{name: "x", goal_reference_xid: Ecto.UUID.generate()})

      assert %{"errors" => %{"goal_reference_xid" => _}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "creates a child under a parent and exposes its parent_reference_xid", %{
      conn: conn,
      scope: scope
    } do
      parent = task_fixture(scope)

      conn =
        post(conn, ~p"/api/tasks",
          task: %{name: "child", parent_reference_xid: parent.reference_xid}
        )

      created = assert_response_schema(conn, 201, "TaskResponse")["data"]
      assert created["parent_reference_xid"] == parent.reference_xid
      refute Map.has_key?(created, "parent_id")
    end

    test "rejects a goal_reference_xid different from the parent's with a field error", %{
      conn: conn,
      scope: scope
    } do
      parent_goal = goal_fixture(scope)
      other_goal = goal_fixture(scope)
      parent = task_fixture(scope, %{goal_reference_xid: parent_goal.reference_xid})

      conn =
        post(conn, ~p"/api/tasks",
          task: %{
            name: "child",
            parent_reference_xid: parent.reference_xid,
            goal_reference_xid: other_goal.reference_xid
          }
        )

      assert %{"errors" => %{"goal_reference_xid" => _}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "rejects an unknown parent_reference_xid with a field error", %{conn: conn} do
      conn =
        post(conn, ~p"/api/tasks",
          task: %{name: "child", parent_reference_xid: Ecto.UUID.generate()}
        )

      assert %{"errors" => %{"parent_reference_xid" => _}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end
  end

  describe "show task" do
    setup [:create_task]

    test "404s for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> get(conn, ~p"/api/tasks/#{other}") end
    end

    test "returns the parent_reference_xid of a child task", %{conn: conn, scope: scope} do
      parent = task_fixture(scope)
      child = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})

      conn = get(conn, ~p"/api/tasks/#{child}")
      data = assert_response_schema(conn, 200, "TaskResponse")["data"]
      assert data["parent_reference_xid"] == parent.reference_xid
    end
  end

  describe "update task" do
    setup [:create_task]

    test "renders the task when data is valid", %{
      conn: conn,
      task: %Task{reference_xid: ref} = task
    } do
      conn = put(conn, ~p"/api/tasks/#{task}", task: @update_attrs)

      assert %{"reference_xid" => ^ref, "name" => "Write more tests"} =
               assert_response_schema(conn, 200, "TaskResponse")["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, task: task} do
      conn = put(conn, ~p"/api/tasks/#{task}", task: @invalid_attrs)
      assert %{"errors" => _} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404s for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> put(conn, ~p"/api/tasks/#{other}", task: @update_attrs) end
    end
  end

  describe "delete task" do
    setup [:create_task]

    test "deletes the chosen task", %{conn: conn, task: task} do
      conn = delete(conn, ~p"/api/tasks/#{task}")
      assert response(conn, 204)
      assert_error_sent 404, fn -> get(conn, ~p"/api/tasks/#{task}") end
    end

    test "404s for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> delete(conn, ~p"/api/tasks/#{other}") end
    end
  end

  defp create_task(%{scope: scope}) do
    %{task: task_fixture(scope)}
  end
end
