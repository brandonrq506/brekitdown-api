defmodule BrekitdownWeb.TaskNoteControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TaskNotesFixtures
  import Brekitdown.TasksFixtures

  setup :register_and_log_in_user

  setup %{conn: conn} do
    {:ok, conn: json_headers(conn)}
  end

  defp json_headers(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
  end

  # A dispatched conn cannot be reused for a second request — recycling leaves the
  # response's content-type on it, which CastAndValidate then rejects. Build a fresh one.
  defp authed_conn(user), do: build_conn() |> log_in_user(user) |> json_headers()

  describe "index (GET /api/tasks/:task_id/notes)" do
    setup %{scope: scope}, do: %{task: task_fixture(scope)}

    test "lists the task's notes newest first", %{conn: conn, scope: scope, task: task} do
      older = task_note_fixture(scope, task, %{title: "Older"})
      newer = task_note_fixture(scope, task, %{title: "Newer"})

      conn = get(conn, ~p"/api/tasks/#{task}/notes")
      data = assert_response_schema(conn, 200, "TaskNotesResponse")["data"]

      assert Enum.map(data, & &1["reference_xid"]) ==
               [newer.reference_xid, older.reference_xid]
    end

    test "returns an empty list when the task has no notes", %{conn: conn, task: task} do
      conn = get(conn, ~p"/api/tasks/#{task}/notes")
      assert assert_response_schema(conn, 200, "TaskNotesResponse")["data"] == []
    end

    test "excludes another task's notes", %{conn: conn, scope: scope, task: task} do
      other_task = task_fixture(scope, %{name: "Other task"})
      note = task_note_fixture(scope, task)
      _other_note = task_note_fixture(scope, other_task)

      conn = get(conn, ~p"/api/tasks/#{task}/notes")
      data = assert_response_schema(conn, 200, "TaskNotesResponse")["data"]

      assert Enum.map(data, & &1["reference_xid"]) == [note.reference_xid]
    end

    test "404 for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())

      assert_error_sent 404, fn -> get(conn, ~p"/api/tasks/#{other}/notes") end
    end
  end

  describe "create (POST /api/tasks/:task_id/notes)" do
    setup %{scope: scope}, do: %{task: task_fixture(scope)}

    test "201, and never leaks internal ids", %{conn: conn, task: task} do
      conn =
        post(conn, ~p"/api/tasks/#{task}/notes",
          note: %{title: "Where I left off", body: "Auth middleware is done."}
        )

      data = assert_response_schema(conn, 201, "TaskNoteResponse")["data"]

      assert data["title"] == "Where I left off"
      assert data["body"] == "Auth middleware is done."
      refute Map.has_key?(data, "id")
      refute Map.has_key?(data, "task_id")
    end

    test "trims surrounding whitespace", %{conn: conn, task: task} do
      conn =
        post(conn, ~p"/api/tasks/#{task}/notes", note: %{title: "  Stuck  ", body: "  On.  "})

      data = assert_response_schema(conn, 201, "TaskNoteResponse")["data"]

      assert data["title"] == "Stuck"
      assert data["body"] == "On."
    end

    # Rejected by CastAndValidate, before the changeset ever runs.
    test "422 when title is missing", %{conn: conn, task: task} do
      conn = post(conn, ~p"/api/tasks/#{task}/notes", note: %{body: "On auth."})

      assert %{"errors" => %{}} = assert_response_schema(conn, 422, "ChangesetError")
    end

    # Reaches the changeset. Same status and envelope as the case above — a client cannot
    # tell the two layers apart, which is what ValidationErrorPlug exists for.
    test "422 when title is blank", %{conn: conn, task: task} do
      conn = post(conn, ~p"/api/tasks/#{task}/notes", note: %{title: "", body: "On auth."})

      assert %{"errors" => %{"title" => ["can't be blank"]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "422 for a title over 100 characters", %{conn: conn, task: task} do
      conn =
        post(conn, ~p"/api/tasks/#{task}/notes",
          note: %{title: String.duplicate("a", 101), body: "On auth."}
        )

      assert %{"errors" => %{}} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "201 for a title of exactly 100 characters", %{conn: conn, task: task} do
      title = String.duplicate("a", 100)
      conn = post(conn, ~p"/api/tasks/#{task}/notes", note: %{title: title, body: "On auth."})

      assert assert_response_schema(conn, 201, "TaskNoteResponse")["data"]["title"] == title
    end

    test "404 for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/tasks/#{other}/notes", note: %{title: "Stuck", body: "On auth."})
      end
    end
  end

  describe "update (PATCH /api/tasks/:task_id/notes/:id)" do
    setup %{scope: scope} do
      task = task_fixture(scope)
      %{task: task, note: task_note_fixture(scope, task, %{title: "Stuck", body: "On auth."})}
    end

    test "updates the body and leaves the title alone", %{conn: conn, task: task, note: note} do
      conn = patch(conn, ~p"/api/tasks/#{task}/notes/#{note}", note: %{body: "Unstuck."})

      data = assert_response_schema(conn, 200, "TaskNoteResponse")["data"]

      assert data["body"] == "Unstuck."
      assert data["title"] == "Stuck"
    end

    test "422 when blanking a field", %{conn: conn, task: task, note: note} do
      conn = patch(conn, ~p"/api/tasks/#{task}/notes/#{note}", note: %{body: "   "})

      assert %{"errors" => %{"body" => ["can't be blank"]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404 for the right note under the wrong task", %{conn: conn, scope: scope, note: note} do
      other_task = task_fixture(scope, %{name: "Other task"})

      assert_error_sent 404, fn ->
        patch(conn, ~p"/api/tasks/#{other_task}/notes/#{note}", note: %{body: "Unstuck."})
      end
    end

    test "404 for another user's note", %{conn: conn, task: task} do
      other_scope = user_scope_fixture()
      other_note = task_note_fixture(other_scope, task_fixture(other_scope))

      assert_error_sent 404, fn ->
        patch(conn, ~p"/api/tasks/#{task}/notes/#{other_note}", note: %{body: "Unstuck."})
      end
    end
  end

  describe "delete (DELETE /api/tasks/:task_id/notes/:id)" do
    setup %{scope: scope} do
      task = task_fixture(scope)
      %{task: task, note: task_note_fixture(scope, task)}
    end

    test "204 and the note stops being listed", %{
      conn: conn,
      user: user,
      task: task,
      note: note
    } do
      assert conn |> delete(~p"/api/tasks/#{task}/notes/#{note}") |> response(204)

      conn = get(authed_conn(user), ~p"/api/tasks/#{task}/notes")
      assert assert_response_schema(conn, 200, "TaskNotesResponse")["data"] == []
    end

    test "404 for the right note under the wrong task", %{conn: conn, scope: scope, note: note} do
      other_task = task_fixture(scope, %{name: "Other task"})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/tasks/#{other_task}/notes/#{note}")
      end
    end

    test "404 for another user's note", %{conn: conn, task: task} do
      other_scope = user_scope_fixture()
      other_note = task_note_fixture(other_scope, task_fixture(other_scope))

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/tasks/#{task}/notes/#{other_note}")
      end
    end
  end

  describe "authentication" do
    test "401 without a token", %{scope: scope} do
      task = task_fixture(scope)

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/tasks/#{task}/notes")

      assert assert_response_schema(conn, 401, "Error")
    end
  end
end
