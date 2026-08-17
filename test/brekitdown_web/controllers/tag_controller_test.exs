defmodule BrekitdownWeb.TagControllerTest do
  use BrekitdownWeb.ConnCase, async: true

  import Brekitdown.TagsFixtures
  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]

  alias Brekitdown.Tags.Tag

  @create_attrs %{name: "Work"}
  @update_attrs %{name: "Personal"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  setup %{conn: conn} do
    {:ok,
     conn:
       conn
       |> put_req_header("accept", "application/json")
       |> put_req_header("content-type", "application/json")}
  end

  describe "index" do
    test "lists only the current user's tags", %{conn: conn, scope: scope} do
      tag = tag_fixture(scope)
      _other = tag_fixture(user_scope_fixture())
      conn = get(conn, ~p"/api/tags")

      assert [%{"reference_xid" => ref}] =
               assert_response_schema(conn, 200, "TagsResponse")["data"]

      assert ref == tag.reference_xid
    end
  end

  describe "create tag" do
    test "renders the tag when valid", %{conn: conn} do
      conn = post(conn, ~p"/api/tags", tag: @create_attrs)
      created = assert_response_schema(conn, 201, "TagResponse")["data"]
      assert %{"reference_xid" => _, "name" => "Work"} = created
      assert is_binary(created["inserted_at"])
      assert is_binary(created["updated_at"])
      refute Map.has_key?(created, "id")
      refute Map.has_key?(created, "user_id")
    end

    test "rejects a case-insensitive duplicate for the same user", %{conn: conn, scope: scope} do
      tag_fixture(scope, %{name: "Work"})
      conn = post(conn, ~p"/api/tags", tag: %{name: "work"})
      assert %{"errors" => %{"name" => _}} = assert_response_schema(conn, 422, "ChangesetError")
    end

    test "errors when name missing", %{conn: conn} do
      conn = post(conn, ~p"/api/tags", tag: @invalid_attrs)
      assert %{"errors" => %{"name" => _}} = assert_response_schema(conn, 422, "ChangesetError")
    end
  end

  describe "update / delete / show" do
    setup %{scope: scope}, do: %{tag: tag_fixture(scope)}

    test "updates", %{conn: conn, tag: %Tag{reference_xid: ref} = tag} do
      conn = put(conn, ~p"/api/tags/#{tag}", tag: @update_attrs)

      assert %{"reference_xid" => ^ref, "name" => "Personal"} =
               assert_response_schema(conn, 200, "TagResponse")["data"]
    end

    test "deletes", %{conn: conn, tag: tag} do
      assert response(delete(conn, ~p"/api/tags/#{tag}"), 204)
      assert_error_sent 404, fn -> get(conn, ~p"/api/tags/#{tag}") end
    end

    test "404s for another user's tag", %{conn: conn} do
      other = tag_fixture(user_scope_fixture())
      assert_error_sent 404, fn -> get(conn, ~p"/api/tags/#{other}") end
    end
  end
end
