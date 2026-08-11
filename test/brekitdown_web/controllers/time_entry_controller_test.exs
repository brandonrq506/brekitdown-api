defmodule BrekitdownWeb.TimeEntryControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TasksFixtures
  import Brekitdown.TimeEntriesFixtures

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

  defp hours_ago(hours),
    do: hours |> shift_back() |> DateTime.to_iso8601()

  defp now, do: DateTime.utc_now(:second) |> DateTime.to_iso8601()

  defp shift_back(hours), do: DateTime.utc_now(:second) |> DateTime.shift(hour: -hours)

  defp five_hours_ago, do: shift_back(5)
  defp four_hours_ago, do: shift_back(4)

  describe "index (GET /api/tasks/:task_id/time_entries)" do
    setup %{scope: scope}, do: %{task: task_fixture(scope)}

    test "lists the task's entries ordered by started_at", %{conn: conn, scope: scope, task: task} do
      recent = time_entry_fixture(scope, task)

      older =
        time_entry_fixture(scope, task, %{
          started_at: five_hours_ago(),
          ended_at: four_hours_ago()
        })

      conn = get(conn, ~p"/api/tasks/#{task}/time_entries")
      data = assert_response_schema(conn, 200, "TimeEntriesResponse")["data"]

      assert Enum.map(data, & &1["reference_xid"]) ==
               [older.reference_xid, recent.reference_xid]
    end

    test "returns an empty list when the task has no entries", %{conn: conn, task: task} do
      conn = get(conn, ~p"/api/tasks/#{task}/time_entries")
      assert assert_response_schema(conn, 200, "TimeEntriesResponse")["data"] == []
    end

    test "excludes another task's entries", %{conn: conn, scope: scope, task: task} do
      other_task = task_fixture(scope, %{name: "Other task"})
      entry = time_entry_fixture(scope, task)
      _other_entry = time_entry_fixture(scope, other_task)

      conn = get(conn, ~p"/api/tasks/#{task}/time_entries")
      data = assert_response_schema(conn, 200, "TimeEntriesResponse")["data"]

      assert Enum.map(data, & &1["reference_xid"]) == [entry.reference_xid]
    end

    test "404 for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())

      assert_error_sent 404, fn -> get(conn, ~p"/api/tasks/#{other}/time_entries") end
    end
  end

  describe "create (POST /api/tasks/:task_id/time_entries)" do
    setup %{scope: scope}, do: %{task: task_fixture(scope)}

    test "201 with started_at only, and never leaks internal ids", %{conn: conn, task: task} do
      started_at = hours_ago(2)

      conn =
        post(conn, ~p"/api/tasks/#{task}/time_entries", time_entry: %{started_at: started_at})

      data = assert_response_schema(conn, 201, "TimeEntryResponse")["data"]

      assert data["started_at"] == started_at
      assert data["ended_at"] == nil
      assert data["reference_xid"]

      refute Map.has_key?(data, "id")
      refute Map.has_key?(data, "user_id")
      refute Map.has_key?(data, "task_id")
    end

    test "201 for a retroactive finished entry", %{conn: conn, task: task} do
      started_at = hours_ago(5)
      ended_at = hours_ago(4)

      conn =
        post(conn, ~p"/api/tasks/#{task}/time_entries",
          time_entry: %{started_at: started_at, ended_at: ended_at}
        )

      data = assert_response_schema(conn, 201, "TimeEntryResponse")["data"]

      assert data["started_at"] == started_at
      assert data["ended_at"] == ended_at
    end

    test "409 on a task that has subtasks", %{conn: conn, scope: scope} do
      parent = task_fixture(scope)
      _child = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})

      conn =
        post(conn, ~p"/api/tasks/#{parent}/time_entries", time_entry: %{started_at: hours_ago(2)})

      body = assert_response_schema(conn, 409, "ConflictError")

      assert body["errors"]["code"] == "not_a_leaf_task"
      assert body["errors"]["detail"] =~ "subtasks"
    end

    test "409 when an entry is already running on the task", %{
      conn: conn,
      scope: scope,
      task: task
    } do
      _open = time_entry_fixture(scope, task, %{ended_at: nil})

      conn = post(conn, ~p"/api/tasks/#{task}/time_entries", time_entry: %{started_at: now()})
      body = assert_response_schema(conn, 409, "ConflictError")

      assert body["errors"]["code"] == "entry_already_running"
      assert body["errors"]["detail"] =~ "has not ended"
    end

    test "422 when started_at is missing", %{conn: conn, task: task} do
      conn = post(conn, ~p"/api/tasks/#{task}/time_entries", time_entry: %{})

      assert %{"errors" => %{"started_at" => [_ | _]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "422 when ended_at precedes started_at", %{conn: conn, task: task} do
      conn =
        post(conn, ~p"/api/tasks/#{task}/time_entries",
          time_entry: %{started_at: hours_ago(1), ended_at: hours_ago(2)}
        )

      assert %{"errors" => %{"ended_at" => ["must not be before started_at"]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "422 for a timestamp with no UTC offset", %{conn: conn, task: task} do
      conn =
        post(conn, ~p"/api/tasks/#{task}/time_entries",
          time_entry: %{started_at: "2026-08-01T10:00:00"}
        )

      assert %{"errors" => %{"started_at" => [_ | _]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404 for another user's task", %{conn: conn} do
      other = task_fixture(user_scope_fixture())

      assert_error_sent 404, fn ->
        post(conn, ~p"/api/tasks/#{other}/time_entries", time_entry: %{started_at: hours_ago(2)})
      end
    end
  end

  describe "update (PATCH /api/tasks/:task_id/time_entries/:id)" do
    setup %{scope: scope} do
      task = task_fixture(scope)
      %{task: task, entry: time_entry_fixture(scope, task, %{ended_at: nil})}
    end

    test "stops an open entry, then un-stops it", %{
      conn: conn,
      user: user,
      task: task,
      entry: entry
    } do
      ended_at = now()

      conn =
        patch(conn, ~p"/api/tasks/#{task}/time_entries/#{entry}",
          time_entry: %{ended_at: ended_at}
        )

      stopped = assert_response_schema(conn, 200, "TimeEntryResponse")["data"]
      assert stopped["ended_at"] == ended_at

      conn =
        patch(authed_conn(user), ~p"/api/tasks/#{task}/time_entries/#{entry}",
          time_entry: %{ended_at: nil}
        )

      resumed = assert_response_schema(conn, 200, "TimeEntryResponse")["data"]

      assert resumed["ended_at"] == nil
      assert resumed["reference_xid"] == entry.reference_xid
    end

    test "edits started_at", %{conn: conn, task: task, entry: entry} do
      started_at = hours_ago(3)

      conn =
        patch(conn, ~p"/api/tasks/#{task}/time_entries/#{entry}",
          time_entry: %{started_at: started_at}
        )

      assert assert_response_schema(conn, 200, "TimeEntryResponse")["data"]["started_at"] ==
               started_at
    end

    test "409 when un-stopping would leave two entries open", %{
      conn: conn,
      scope: scope,
      task: task
    } do
      # the setup's entry is already open on this task; this one is finished
      finished =
        time_entry_fixture(scope, task, %{
          started_at: five_hours_ago(),
          ended_at: four_hours_ago()
        })

      conn =
        patch(conn, ~p"/api/tasks/#{task}/time_entries/#{finished}", time_entry: %{ended_at: nil})

      body = assert_response_schema(conn, 409, "ConflictError")

      assert body["errors"]["code"] == "entry_already_running"
      assert body["errors"]["detail"] =~ "has not ended"
    end

    test "422 when the new started_at is after the stored ended_at", %{
      conn: conn,
      scope: scope,
      task: task
    } do
      finished =
        time_entry_fixture(scope, task, %{
          started_at: five_hours_ago(),
          ended_at: four_hours_ago()
        })

      conn =
        patch(conn, ~p"/api/tasks/#{task}/time_entries/#{finished}",
          time_entry: %{started_at: now()}
        )

      assert %{"errors" => %{"ended_at" => ["must not be before started_at"]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "404 for the right entry under the wrong task", %{conn: conn, scope: scope, entry: entry} do
      other_task = task_fixture(scope, %{name: "Other task"})

      assert_error_sent 404, fn ->
        patch(conn, ~p"/api/tasks/#{other_task}/time_entries/#{entry}",
          time_entry: %{ended_at: now()}
        )
      end
    end

    test "404 for another user's entry", %{conn: conn, task: task} do
      other_scope = user_scope_fixture()
      other_entry = time_entry_fixture(other_scope, task_fixture(other_scope))

      assert_error_sent 404, fn ->
        patch(conn, ~p"/api/tasks/#{task}/time_entries/#{other_entry}",
          time_entry: %{ended_at: now()}
        )
      end
    end
  end

  describe "delete (DELETE /api/tasks/:task_id/time_entries/:id)" do
    setup %{scope: scope} do
      task = task_fixture(scope)
      %{task: task, entry: time_entry_fixture(scope, task)}
    end

    test "204 and the entry stops being listed", %{
      conn: conn,
      user: user,
      task: task,
      entry: entry
    } do
      assert response(delete(conn, ~p"/api/tasks/#{task}/time_entries/#{entry}"), 204)

      conn = get(authed_conn(user), ~p"/api/tasks/#{task}/time_entries")
      assert assert_response_schema(conn, 200, "TimeEntriesResponse")["data"] == []
    end

    test "204 and an in_progress task resets to scheduled", %{
      conn: conn,
      scope: scope,
      user: user
    } do
      task = task_fixture(scope, %{status: :in_progress})
      entry = time_entry_fixture(scope, task)

      assert response(delete(conn, ~p"/api/tasks/#{task}/time_entries/#{entry}"), 204)

      conn = get(authed_conn(user), ~p"/api/tasks/#{task}")
      assert assert_response_schema(conn, 200, "TaskResponse")["data"]["status"] == "scheduled"
    end

    test "404 for the right entry under the wrong task", %{conn: conn, scope: scope, entry: entry} do
      other_task = task_fixture(scope, %{name: "Other task"})

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/tasks/#{other_task}/time_entries/#{entry}")
      end
    end

    test "404 for another user's entry", %{conn: conn, task: task} do
      other_scope = user_scope_fixture()
      other_entry = time_entry_fixture(other_scope, task_fixture(other_scope))

      assert_error_sent 404, fn ->
        delete(conn, ~p"/api/tasks/#{task}/time_entries/#{other_entry}")
      end
    end
  end

  describe "authentication" do
    test "401 without a token", %{scope: scope} do
      task = task_fixture(scope)

      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/tasks/#{task}/time_entries")

      assert assert_response_schema(conn, 401, "Error")
    end
  end
end
