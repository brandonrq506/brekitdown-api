defmodule Brekitdown.TasksTest do
  use Brekitdown.DataCase

  alias Brekitdown.Tasks
  alias Brekitdown.Tasks.Task

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TasksFixtures
  import Brekitdown.GoalsFixtures

  describe "list_tasks/1" do
    test "returns only the scoped user's tasks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      _other = task_fixture(other_scope)

      assert [listed] = Tasks.list_tasks(scope)
      assert listed.id == task.id
    end
  end

  describe "get_task!/2" do
    test "returns the scoped task by reference_xid" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert Tasks.get_task!(scope, task.reference_xid).id == task.id
    end

    test "hides another user's task" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise Ecto.NoResultsError, fn ->
        Tasks.get_task!(other_scope, task.reference_xid)
      end
    end
  end

  describe "create_task/2" do
    test "with valid data creates a scheduled, goal-less task" do
      scope = user_scope_fixture()

      assert {:ok, %Task{} = task} = Tasks.create_task(scope, %{name: "Write tests"})
      assert task.name == "Write tests"
      assert task.status == :scheduled
      assert task.goal_id == nil
      assert task.user_id == scope.user.id
      assert {:ok, _} = Ecto.UUID.cast(task.reference_xid)
    end

    test "accepts an explicit status" do
      scope = user_scope_fixture()
      assert {:ok, task} = Tasks.create_task(scope, %{name: "x", status: :in_progress})
      assert task.status == :in_progress
    end

    test "without a name is rejected" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{} = cs} = Tasks.create_task(scope, %{name: nil})
      assert %{name: ["can't be blank"]} = errors_on(cs)
    end

    test "attaches a goal by goal_reference_xid" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)

      assert {:ok, task} =
               Tasks.create_task(scope, %{name: "x", goal_reference_xid: goal.reference_xid})

      assert task.goal_id == goal.id
    end

    test "rejects an unknown goal_reference_xid with a field error" do
      scope = user_scope_fixture()

      assert {:error, cs} =
               Tasks.create_task(scope, %{name: "x", goal_reference_xid: Ecto.UUID.generate()})

      assert %{goal_reference_xid: ["does not exist"]} = errors_on(cs)
    end

    test "cannot attach another user's goal (looks like it does not exist)" do
      scope = user_scope_fixture()
      other_goal = goal_fixture(user_scope_fixture())

      assert {:error, cs} =
               Tasks.create_task(scope, %{name: "x", goal_reference_xid: other_goal.reference_xid})

      assert %{goal_reference_xid: ["does not exist"]} = errors_on(cs)
    end
  end

  describe "update_task/3" do
    test "updates name and due_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      new_due = DateTime.utc_now() |> DateTime.shift(day: 2) |> DateTime.truncate(:second)

      assert {:ok, updated} = Tasks.update_task(scope, task, %{name: "renamed", due_at: new_due})
      assert updated.name == "renamed"
      assert updated.due_at == new_due
    end

    test "ignores status (not settable via the generic update)" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, updated} = Tasks.update_task(scope, task, %{name: "x", status: :completed})
      assert updated.status == :scheduled
    end

    test "with invalid data errors and leaves the row unchanged" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(scope, task, %{name: nil})
      assert Tasks.get_task!(scope, task.reference_xid).name == task.name
    end

    test "with a non-owner scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise MatchError, fn -> Tasks.update_task(other_scope, task, %{name: "x"}) end
    end
  end

  describe "delete_task/2" do
    test "deletes the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, %Task{}} = Tasks.delete_task(scope, task)
      assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, task.reference_xid) end
    end

    test "with a non-owner scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise MatchError, fn -> Tasks.delete_task(other_scope, task) end
    end
  end

  test "deleting a goal deletes its tasks" do
    scope = user_scope_fixture()
    goal = goal_fixture(scope)
    task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})

    assert {:ok, _} = Brekitdown.Goals.delete_goal(scope, goal)
    assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, task.reference_xid) end
  end

  test "change_task/2 returns a changeset" do
    scope = user_scope_fixture()
    task = task_fixture(scope)
    assert %Ecto.Changeset{} = Tasks.change_task(scope, task)
  end
end
