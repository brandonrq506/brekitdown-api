defmodule Brekitdown.TasksTest do
  use Brekitdown.DataCase

  alias Brekitdown.Tags
  alias Brekitdown.Tags.{Tag, TaskTag}
  alias Brekitdown.Tasks
  alias Brekitdown.Tasks.Task

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TasksFixtures
  import Brekitdown.GoalsFixtures
  import Brekitdown.TagsFixtures

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

  describe "attach_tag/4" do
    test "creates the tag and links it to the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, task} = Tasks.attach_tag(scope, task, "Work", [:tags])
      assert [%Tag{name: "Work"}] = task.tags
    end

    test "reuses an existing tag instead of duplicating it" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      {:ok, existing} = Tags.create_tag(scope, %{name: "Work"})

      assert {:ok, task} = Tasks.attach_tag(scope, task, "work", [:tags])
      assert [%Tag{id: id}] = task.tags
      assert id == existing.id
      assert Repo.aggregate(Tag, :count) == 1
    end

    test "is idempotent — attaching the same tag twice keeps one link" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, _} = Tasks.attach_tag(scope, task, "Work")
      assert {:ok, _} = Tasks.attach_tag(scope, task, "Work")
      assert Repo.aggregate(TaskTag, :count) == 1
    end

    test "rejects a blank tag name" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tasks.attach_tag(scope, task, "   ")
    end

    test "with a non-owner scope raises" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert_raise MatchError, fn -> Tasks.attach_tag(user_scope_fixture(), task, "Work") end
    end
  end

  describe "detach_tag/3" do
    test "removes the link but keeps the tag" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      {:ok, _} = Tasks.attach_tag(scope, task, "Work")
      {:ok, tag} = Tags.find_or_create_tag(scope, "Work")

      assert :ok = Tasks.detach_tag(scope, task, tag.reference_xid)
      assert Repo.aggregate(TaskTag, :count) == 0
      assert Tags.get_tag!(scope, tag.reference_xid).id == tag.id
    end

    test "is a no-op when the tag is not attached" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      tag = tag_fixture(scope)
      assert :ok = Tasks.detach_tag(scope, task, tag.reference_xid)
    end

    test "raises for another user's tag reference" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_tag = tag_fixture(user_scope_fixture())

      assert_raise Ecto.NoResultsError, fn ->
        Tasks.detach_tag(scope, task, other_tag.reference_xid)
      end
    end

    test "with a non-owner scope raises" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      tag = tag_fixture(scope)

      assert_raise MatchError, fn ->
        Tasks.detach_tag(user_scope_fixture(), task, tag.reference_xid)
      end
    end
  end

  describe "tagging cascades" do
    test "deleting a task removes its tag links but keeps the tags" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      {:ok, _} = Tasks.attach_tag(scope, task, "Work")
      {:ok, tag} = Tags.find_or_create_tag(scope, "Work")

      assert {:ok, _} = Tasks.delete_task(scope, task)
      assert Repo.aggregate(TaskTag, :count) == 0
      assert Tags.get_tag!(scope, tag.reference_xid).id == tag.id
    end

    test "deleting a tag removes its links but keeps the tasks" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      {:ok, _} = Tasks.attach_tag(scope, task, "Work")
      {:ok, tag} = Tags.find_or_create_tag(scope, "Work")

      assert {:ok, _} = Tags.delete_tag(scope, tag)
      assert Repo.aggregate(TaskTag, :count) == 0
      assert Tasks.get_task!(scope, task.reference_xid).id == task.id
    end
  end
end
