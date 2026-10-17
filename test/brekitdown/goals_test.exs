defmodule Brekitdown.GoalsTest do
  use Brekitdown.DataCase

  alias Brekitdown.Goals
  alias Brekitdown.Tasks

  describe "goals" do
    alias Brekitdown.Goals.Goal

    import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
    import Brekitdown.GoalsFixtures
    import Brekitdown.TasksFixtures, only: [task_fixture: 1, task_fixture: 2]

    @invalid_attrs %{name: nil, description: nil}

    test "paginated_list/2 returns only scoped goals with pagination metadata" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      goal = goal_fixture(scope)
      other_goal = goal_fixture(other_scope)

      assert {:ok, {[result], %Flop.Meta{total_count: 1, page_size: 20}}} =
               Goals.paginated_list(scope)

      assert result == goal

      assert {:ok, {[other_result], %Flop.Meta{total_count: 1, page_size: 20}}} =
               Goals.paginated_list(other_scope)

      assert other_result == other_goal
    end

    test "paginated_list/2 lists starred goals first and alphabetizes each group" do
      scope = user_scope_fixture()

      unstarred_zebra = goal_fixture(scope, %{name: "Zebra"})

      starred_yarrow =
        goal_fixture(scope, %{name: "Yarrow", starred_at: ~U[2026-09-13 12:00:00Z]})

      unstarred_apple = goal_fixture(scope, %{name: "Apple"})

      starred_birch =
        goal_fixture(scope, %{name: "Birch", starred_at: ~U[2026-09-13 11:00:00Z]})

      assert {:ok, {goals, %Flop.Meta{total_count: 4}}} = Goals.paginated_list(scope)

      assert goals == [starred_birch, starred_yarrow, unstarred_apple, unstarred_zebra]
    end

    test "paginated_list/2 filters by completed and returns everything without a filter" do
      scope = user_scope_fixture()
      open = goal_fixture(scope, %{name: "Open"})
      {:ok, completed} = Goals.complete_goal(scope, goal_fixture(scope, %{name: "Done"}))

      filter = fn value -> %{filters: [%{field: :completed, op: :==, value: value}]} end

      assert {:ok, {[^open], _meta}} = Goals.paginated_list(scope, filter.(false))
      assert {:ok, {[^completed], _meta}} = Goals.paginated_list(scope, filter.(true))
      assert {:ok, {[^completed, ^open], _meta}} = Goals.paginated_list(scope)
    end

    test "page size menu is consistent with Flop limits" do
      assert Enum.max(Goal.page_sizes()) == Flop.get_option(:max_limit, for: Goal)
      assert Flop.get_option(:default_limit, for: Goal) in Goal.page_sizes()
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
      assert is_nil(goal.archived_at)
      assert is_nil(goal.starred_at)
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

    test "update_goal/3 sets and clears goal organization timestamps" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      timestamp = ~U[2026-09-13 12:00:00Z]

      assert {:ok, %Goal{} = goal} =
               Goals.update_goal(scope, goal, %{
                 archived_at: timestamp,
                 starred_at: timestamp
               })

      assert goal.archived_at == timestamp
      assert goal.starred_at == timestamp

      assert {:ok, %Goal{} = goal} =
               Goals.update_goal(scope, goal, %{
                 archived_at: nil,
                 starred_at: nil
               })

      assert is_nil(goal.archived_at)
      assert is_nil(goal.starred_at)
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

    test "complete_goal/2 sets completed_at" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert {:ok, %Goal{completed_at: %DateTime{}}} = Goals.complete_goal(scope, goal)
    end

    test "complete_goal/2 keeps the original completed_at when already completed" do
      scope = user_scope_fixture()
      {:ok, completed} = Goals.complete_goal(scope, goal_fixture(scope))

      assert {:ok, again} = Goals.complete_goal(scope, completed)
      assert again.completed_at == completed.completed_at
    end

    test "complete_goal/2 drops every open task of the goal, subtasks included" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)

      scheduled = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})

      in_progress =
        task_fixture(scope, %{goal_reference_xid: goal.reference_xid, status: :in_progress})

      on_hold = task_fixture(scope, %{goal_reference_xid: goal.reference_xid, status: :on_hold})
      subtask = task_fixture(scope, %{parent_reference_xid: scheduled.reference_xid})

      assert {:ok, _goal} = Goals.complete_goal(scope, goal)

      for task <- [scheduled, in_progress, on_hold, subtask] do
        assert Tasks.get_task!(scope, task.reference_xid).status == :dropped
      end
    end

    test "complete_goal/2 leaves closed tasks and other goals' tasks untouched" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      other_goal = goal_fixture(scope)

      completed =
        task_fixture(scope, %{goal_reference_xid: goal.reference_xid, status: :completed})

      dropped = task_fixture(scope, %{goal_reference_xid: goal.reference_xid, status: :dropped})
      other_goal_task = task_fixture(scope, %{goal_reference_xid: other_goal.reference_xid})
      no_goal_task = task_fixture(scope)

      assert {:ok, _goal} = Goals.complete_goal(scope, goal)

      for task <- [completed, dropped, other_goal_task, no_goal_task] do
        assert Tasks.get_task!(scope, task.reference_xid) == task
      end
    end

    test "complete_goal/2 on an already-completed goal changes no tasks" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
      {:ok, completed} = Goals.complete_goal(scope, goal)

      # Bypasses the context on purpose: an open task in a completed goal is a state the
      # app forbids, forced here only to prove a repeat completion leaves tasks alone.
      {:ok, _task} =
        scope
        |> Tasks.get_task!(task.reference_xid)
        |> change(status: :scheduled)
        |> Repo.update()

      assert {:ok, _goal} = Goals.complete_goal(scope, completed)
      assert Tasks.get_task!(scope, task.reference_xid).status == :scheduled
    end

    test "complete_goal/2 is atomic: if dropping tasks fails, the goal is not completed" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})

      # Rolled back with the sandbox transaction. Safe because this module runs sync.
      Repo.query!("""
      ALTER TABLE tasks ADD CONSTRAINT test_no_dropped_tasks CHECK (status <> 'dropped') NOT VALID
      """)

      assert_raise Postgrex.Error, fn -> Goals.complete_goal(scope, goal) end

      assert Goals.get_goal!(scope, goal.reference_xid).completed_at == nil
      assert Tasks.get_task!(scope, task.reference_xid).status == :scheduled
    end

    test "complete_goal/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert_raise MatchError, fn -> Goals.complete_goal(other_scope, goal) end
    end

    test "reopen_goal/2 clears completed_at" do
      scope = user_scope_fixture()
      {:ok, completed} = Goals.complete_goal(scope, goal_fixture(scope))

      assert {:ok, %Goal{completed_at: nil}} = Goals.reopen_goal(scope, completed)
      assert Goals.get_goal!(scope, completed.reference_xid).completed_at == nil
    end

    test "reopen_goal/2 on a goal that is not completed returns it unchanged" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)

      assert {:ok, ^goal} = Goals.reopen_goal(scope, goal)
    end

    test "reopen_goal/2 leaves dropped tasks dropped" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
      {:ok, completed} = Goals.complete_goal(scope, goal)

      assert {:ok, _goal} = Goals.reopen_goal(scope, completed)
      assert Tasks.get_task!(scope, task.reference_xid).status == :dropped
    end

    test "reopen_goal/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      {:ok, completed} = Goals.complete_goal(scope, goal_fixture(scope))
      assert_raise MatchError, fn -> Goals.reopen_goal(other_scope, completed) end
    end

    test "update_goal/3 ignores completed_at" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)

      assert {:ok, %Goal{completed_at: nil}} =
               Goals.update_goal(scope, goal, %{completed_at: ~U[2026-01-01 00:00:00Z]})
    end

    test "change_goal/2 returns a goal changeset" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      assert %Ecto.Changeset{} = Goals.change_goal(scope, goal)
    end
  end
end
