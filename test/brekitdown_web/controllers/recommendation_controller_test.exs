defmodule BrekitdownWeb.RecommendationControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.TasksFixtures
  import Brekitdown.GoalsFixtures
  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]

  @response "RecommendationsResponse"

  setup :register_and_log_in_user

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "index" do
    test "orders by due_at ascending and excludes ineligible tasks", %{conn: conn, scope: scope} do
      goal = goal_fixture(scope)
      later = task_fixture(scope, %{name: "later", due_at: due_in(2)})

      sooner =
        task_fixture(scope, %{
          name: "sooner",
          due_at: due_in(1),
          status: :in_progress,
          goal_reference_xid: goal.reference_xid
        })

      _no_due_date = task_fixture(scope, %{due_at: nil})
      _completed = task_fixture(scope, %{status: :completed})
      _dropped = task_fixture(scope, %{status: :dropped})
      _on_hold = task_fixture(scope, %{status: :on_hold})
      _other_user = task_fixture(user_scope_fixture())

      body = conn |> get(~p"/api/recommendations") |> assert_response_schema(200, @response)

      assert Enum.map(body["data"], & &1["reference_xid"]) ==
               [sooner.reference_xid, later.reference_xid]

      assert [%{"goal" => rendered_goal} | _] = body["data"]
      assert rendered_goal == %{"reference_xid" => goal.reference_xid, "name" => goal.name}
    end

    test "breaks due_at ties deterministically across requests", %{conn: conn, scope: scope} do
      same_due_at = due_in(1)
      first = task_fixture(scope, %{name: "first", due_at: same_due_at})
      second = task_fixture(scope, %{name: "second", due_at: same_due_at})

      refs = fn ->
        conn
        |> get(~p"/api/recommendations")
        |> assert_response_schema(200, @response)
        |> Map.fetch!("data")
        |> Enum.map(& &1["reference_xid"])
      end

      assert refs.() == [first.reference_xid, second.reference_xid]
      assert refs.() == [first.reference_xid, second.reference_xid]
    end

    test "pages with a cursor without overlap", %{conn: conn, scope: scope} do
      tasks = for days <- 1..3, do: task_fixture(scope, %{due_at: due_in(days)})
      [task_1, task_2, task_3] = Enum.map(tasks, & &1.reference_xid)

      page_1 =
        conn
        |> get(~p"/api/recommendations?first=2")
        |> assert_response_schema(200, @response)

      assert Enum.map(page_1["data"], & &1["reference_xid"]) == [task_1, task_2]

      assert %{"page_size" => 2, "has_next_page" => true, "end_cursor" => cursor} =
               page_1["meta"]

      assert is_binary(cursor)

      page_2 =
        conn
        |> get(~p"/api/recommendations?first=2&after=#{cursor}")
        |> assert_response_schema(200, @response)

      assert Enum.map(page_2["data"], & &1["reference_xid"]) == [task_3]
      assert page_2["meta"]["has_next_page"] == false
    end

    test "returns an empty page when nothing is recommendable", %{conn: conn, scope: scope} do
      _completed = task_fixture(scope, %{status: :completed})

      body = conn |> get(~p"/api/recommendations") |> assert_response_schema(200, @response)

      assert body["data"] == []

      assert body["meta"] == %{
               "page_size" => 20,
               "has_next_page" => false,
               "end_cursor" => nil
             }
    end

    test "rejects a page size above the maximum", %{conn: conn} do
      conn = get(conn, ~p"/api/recommendations?first=51")

      assert %{"errors" => %{"first" => [_message]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "rejects a malformed cursor", %{conn: conn} do
      conn = get(conn, ~p"/api/recommendations?first=2&after=not-a-cursor")

      assert %{"errors" => %{"after" => [_message]}} =
               assert_response_schema(conn, 422, "ChangesetError")
    end

    test "returns 401 without a token" do
      conn =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/recommendations")

      assert_response_schema(conn, 401, "Error")
    end
  end

  defp due_in(days) do
    DateTime.utc_now() |> DateTime.add(days, :day) |> DateTime.truncate(:second)
  end
end
