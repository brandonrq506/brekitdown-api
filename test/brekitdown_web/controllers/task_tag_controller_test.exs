defmodule BrekitdownWeb.TaskTagControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.TasksFixtures
  import Brekitdown.TagsFixtures
  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]

  alias Brekitdown.Tasks

  setup :register_and_log_in_user

  setup %{conn: conn} do
    {:ok,
     conn:
       conn
       |> put_req_header("accept", "application/json")
       |> put_req_header("content-type", "application/json")}
  end

  describe "attach (POST /api/tasks/:task_id/tags)" do
    setup %{scope: scope}, do: %{task: task_fixture(scope)}

    test "attaches a tag by name and returns the task with its tags", %{conn: conn, task: task} do
      conn = post(conn, ~p"/api/tasks/#{task}/tags", name: "Work")
      data = assert_response_schema(conn, 200, "TaskResponse")["data"]

      assert data["reference_xid"] == task.reference_xid
      assert [tag] = data["tags"]
      assert %{"name" => "Work", "reference_xid" => _} = tag
      assert is_binary(tag["inserted_at"])
      assert is_binary(tag["updated_at"])
    end

    test "is idempotent — same name (any case) keeps one tag", %{conn: conn, task: task} do
      post(conn, ~p"/api/tasks/#{task}/tags", name: "Work")
      conn = post(conn, ~p"/api/tasks/#{task}/tags", name: "work")
      data = assert_response_schema(conn, 200, "TaskResponse")["data"]
      assert [%{"name" => "Work"}] = data["tags"]
    end

    test "422 when the name is missing", %{conn: conn, task: task} do
      conn = post(conn, ~p"/api/tasks/#{task}/tags", %{})
      assert %{"errors" => _} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404 for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> post(conn, ~p"/api/tasks/#{other}/tags", name: "Work") end
    end
  end

  describe "detach (DELETE /api/tasks/:task_id/tags/:id)" do
    setup %{scope: scope} do
      task = task_fixture(scope)
      tag = tag_fixture(scope)
      {:ok, _} = Tasks.attach_tag(scope, task, tag.name)
      %{task: task, tag: tag}
    end

    test "detaches the tag and returns 204", %{conn: conn, task: task, tag: tag} do
      assert response(delete(conn, ~p"/api/tasks/#{task}/tags/#{tag}"), 204)

      conn = get(conn, ~p"/api/tasks/#{task}")
      assert assert_response_schema(conn, 200, "TaskResponse")["data"]["tags"] == []
    end

    test "204 (idempotent) when the tag is not attached", %{conn: conn, scope: scope, task: task} do
      spare = tag_fixture(scope, %{name: "Spare"})
      assert response(delete(conn, ~p"/api/tasks/#{task}/tags/#{spare}"), 204)
    end

    test "404 for another user's task", %{conn: conn, tag: tag} do
      other = task_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> delete(conn, ~p"/api/tasks/#{other}/tags/#{tag}") end
    end
  end
end
