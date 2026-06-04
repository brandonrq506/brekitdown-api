defmodule BrekitdownWeb.FallbackControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import ExUnit.CaptureLog

  alias BrekitdownWeb.FallbackController

  setup do
    {:ok, conn: build_conn() |> Phoenix.Controller.put_format("json")}
  end

  test "{:error, :not_found} renders a 404", %{conn: conn} do
    conn = FallbackController.call(conn, {:error, :not_found})
    assert json_response(conn, 404) == %{"errors" => %{"detail" => "Not Found"}}
  end

  test "{:error, :unauthorized} renders a 401", %{conn: conn} do
    conn = FallbackController.call(conn, {:error, :unauthorized})
    assert json_response(conn, 401) == %{"errors" => %{"detail" => "Unauthorized"}}
  end

  test "{:error, :forbidden} renders a 403", %{conn: conn} do
    conn = FallbackController.call(conn, {:error, :forbidden})
    assert json_response(conn, 403) == %{"errors" => %{"detail" => "Forbidden"}}
  end

  test "{:error, :bad_request} renders a 400", %{conn: conn} do
    conn = FallbackController.call(conn, {:error, :bad_request})
    assert json_response(conn, 400) == %{"errors" => %{"detail" => "Bad Request"}}
  end

  test "an unknown reason is logged and rendered as a 500", %{conn: conn} do
    log =
      capture_log(fn ->
        conn = FallbackController.call(conn, {:error, :some_weird_thing})
        assert json_response(conn, 500) == %{"errors" => %{"detail" => "Internal Server Error"}}
      end)

    assert log =~ "some_weird_thing"
  end
end
