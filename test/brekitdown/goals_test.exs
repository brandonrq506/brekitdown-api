defmodule Brekitdown.GoalsTest do
  use Brekitdown.DataCase

  alias Brekitdown.Goals

  describe "goals" do
    alias Brekitdown.Goals.Goal

    import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
    import Brekitdown.GoalsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_goals/1 returns all scoped goals" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      goal = goal_fixture(scope)
      other_goal = goal_fixture(other_scope)
      assert Goals.list_goals(scope) == [goal]
      assert Goals.list_goals(other_scope) == [other_goal]
    end

    test "get_goal!/2 returns the scoped goal with the given reference_xid" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      other_scope = user_scope_fixture()
      assert Goals.get_goal!(scope, goal.reference_xid) == goal
      # the goal exists, but is invisible to a different user's scope
      assert_raise Ecto.NoResultsError, fn ->
        Goals.get_goal!(other_scope, goal.reference_xid)
      end
    end

    test "create_goal/2 with valid data creates a goal" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %Goal{} = goal} = Goals.create_goal(scope, valid_attrs)
      assert goal.name == "some name"
      assert goal.description == "some description"
      assert goal.user_id == scope.user.id
    end

    test "create_goal/2 populates a reference_xid" do
      scope = user_scope_fixture()
      assert {:ok, %Goal{} = goal} = Goals.create_goal(scope, %{name: "some name"})
      assert {:ok, _uuid} = Ecto.UUID.cast(goal.reference_xid)
    end

    test "create_goal/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Goals.create_goal(scope, @invalid_attrs)
    end

    test "create_goal/2 rejects a name longer than 100 characters" do
      scope = user_scope_fixture()
      assert {:error, changeset} = Goals.create_goal(scope, %{name: String.duplicate("a", 101)})
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "update_goal/3 with valid data updates the goal" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Goal{} = goal} = Goals.update_goal(scope, goal, update_attrs)
      assert goal.name == "some updated name"
      assert goal.description == "some updated description"
    end

    test "update_goal/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      goal = goal_fixture(scope)

      assert_raise MatchError, fn ->
        Goals.update_goal(other_scope, goal, %{})
      end
    end

    test "update_goal/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Goals.update_goal(scope, goal, @invalid_attrs)
      assert goal == Goals.get_goal!(scope, goal.reference_xid)
    end

    test "delete_goal/2 deletes the goal" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert {:ok, %Goal{}} = Goals.delete_goal(scope, goal)
      assert_raise Ecto.NoResultsError, fn -> Goals.get_goal!(scope, goal.reference_xid) end
    end

    test "delete_goal/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert_raise MatchError, fn -> Goals.delete_goal(other_scope, goal) end
    end

    test "change_goal/2 returns a goal changeset" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert %Ecto.Changeset{} = Goals.change_goal(scope, goal)
    end
  end
end
