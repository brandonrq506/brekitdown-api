defmodule Brekitdown.TagsTest do
  use Brekitdown.DataCase

  alias Brekitdown.Tags

  describe "tags" do
    alias Brekitdown.Tags.Tag

    import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
    import Brekitdown.TagsFixtures

    @invalid_attrs %{name: nil}

    test "list_tags/1 returns only the scope's tags" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)
      other_tag = tag_fixture(other_scope)

      assert Tags.list_tags(scope) == [tag]
      assert Tags.list_tags(other_scope) == [other_tag]
    end

    test "get_tag!/2 returns the tag by reference_xid" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert Tags.get_tag!(scope, tag.reference_xid) == tag
    end

    test "get_tag!/2 raises for a tag owned by another user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert_raise Ecto.NoResultsError, fn ->
        Tags.get_tag!(other_scope, tag.reference_xid)
      end
    end

    test "get_tag/2 returns the tag for its owner and nil for another user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert Tags.get_tag(scope, tag.reference_xid) == tag
      assert Tags.get_tag(other_scope, tag.reference_xid) == nil
    end

    test "create_tag/2 with valid data creates a tag" do
      scope = user_scope_fixture()

      assert {:ok, %Tag{} = tag} = Tags.create_tag(scope, %{name: "Work"})
      assert tag.name == "Work"
      assert tag.user_id == scope.user.id
      assert tag.reference_xid
    end

    test "create_tag/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Tags.create_tag(scope, @invalid_attrs)
    end

    test "create_tag/2 trims and collapses whitespace in the name" do
      scope = user_scope_fixture()

      assert {:ok, %Tag{} = tag} = Tags.create_tag(scope, %{name: "  Deep   Work  "})
      assert tag.name == "Deep Work"
    end

    test "create_tag/2 rejects a case-insensitive duplicate name for the same user" do
      scope = user_scope_fixture()

      assert {:ok, %Tag{}} = Tags.create_tag(scope, %{name: "Work"})
      assert {:error, changeset} = Tags.create_tag(scope, %{name: "work"})
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "create_tag/2 treats whitespace and case variants as duplicates" do
      scope = user_scope_fixture()

      assert {:ok, %Tag{}} = Tags.create_tag(scope, %{name: "Deep Work"})
      assert {:error, changeset} = Tags.create_tag(scope, %{name: "  deep   work "})
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "create_tag/2 allows the same name for different users" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      assert {:ok, %Tag{}} = Tags.create_tag(scope, %{name: "Work"})
      assert {:ok, %Tag{}} = Tags.create_tag(other_scope, %{name: "Work"})
    end

    test "update_tag/3 with valid data updates the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert {:ok, %Tag{} = tag} = Tags.update_tag(scope, tag, %{name: "Renamed"})
      assert tag.name == "Renamed"
    end

    test "update_tag/3 with invalid data returns error changeset and leaves the tag unchanged" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(scope, tag, @invalid_attrs)
      assert tag == Tags.get_tag!(scope, tag.reference_xid)
    end

    test "update_tag/3 for a tag owned by another user raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert_raise MatchError, fn ->
        Tags.update_tag(other_scope, tag, %{name: "Renamed"})
      end
    end

    test "delete_tag/2 deletes the tag" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert {:ok, %Tag{}} = Tags.delete_tag(scope, tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(scope, tag.reference_xid) end
    end

    test "delete_tag/2 for a tag owned by another user raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert_raise MatchError, fn -> Tags.delete_tag(other_scope, tag) end
    end

    test "change_tag/2 returns a tag changeset" do
      scope = user_scope_fixture()
      tag = tag_fixture(scope)

      assert %Ecto.Changeset{} = Tags.change_tag(scope, tag)
    end

    test "find_or_create_tag/2 creates a new tag when none matches" do
      scope = user_scope_fixture()

      assert {:ok, %Tag{} = tag} = Tags.find_or_create_tag(scope, "Work")
      assert tag.name == "Work"
      assert tag.user_id == scope.user.id
    end

    test "find_or_create_tag/2 reuses an existing tag (case- and whitespace-insensitive)" do
      scope = user_scope_fixture()
      {:ok, existing} = Tags.create_tag(scope, %{name: "Deep Work"})

      assert {:ok, reused} = Tags.find_or_create_tag(scope, "  deep   work ")
      assert reused.id == existing.id
      # original display casing is preserved, not overwritten
      assert reused.name == "Deep Work"
      assert Tags.list_tags(scope) == [existing]
    end

    test "find_or_create_tag/2 is scoped per user" do
      scope = user_scope_fixture()
      {:ok, _other} = Tags.create_tag(user_scope_fixture(), %{name: "Work"})

      assert {:ok, tag} = Tags.find_or_create_tag(scope, "Work")
      assert tag.user_id == scope.user.id
      assert Tags.list_tags(scope) == [tag]
    end

    test "find_or_create_tag/2 with a blank name returns an error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tags.find_or_create_tag(scope, "   ")
    end
  end
end
