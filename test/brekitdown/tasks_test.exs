defmodule Brekitdown.TasksTest do
  use Brekitdown.DataCase

  alias Brekitdown.Tags
  alias Brekitdown.Tags.{Tag, TaskTag}
  alias Brekitdown.Tasks
  alias Brekitdown.Tasks.Task

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TaskNotesFixtures
  import Brekitdown.TasksFixtures
  import Brekitdown.GoalsFixtures
  import Brekitdown.TagsFixtures

  describe "list_tasks/3" do
    test "returns only the scoped user's tasks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      _other = task_fixture(other_scope)

      assert {:ok, [listed]} = Tasks.list_tasks(scope)
      assert listed.id == task.id
    end

    test "includes tasks that have a parent" do
      scope = user_scope_fixture()
      parent = task_fixture(scope)
      child = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})

      {:ok, tasks} = Tasks.list_tasks(scope)
      ids = tasks |> Enum.map(& &1.id) |> Enum.sort()
      assert ids == Enum.sort([parent.id, child.id])
    end

    test "filters by goal_reference_xid, excluding other goals and goal-less tasks" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      other_goal = goal_fixture(scope)
      in_goal = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
      _in_other = task_fixture(scope, %{goal_reference_xid: other_goal.reference_xid})
      _goalless = task_fixture(scope)

      assert {:ok, [listed]} = Tasks.list_tasks(scope, goal_filter(goal.reference_xid))
      assert listed.id == in_goal.id
    end

    test "filtering by another user's goal returns no tasks" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      other_goal = goal_fixture(other_scope)
      _other_task = task_fixture(other_scope, %{goal_reference_xid: other_goal.reference_xid})

      assert {:ok, []} = Tasks.list_tasks(scope, goal_filter(other_goal.reference_xid))
    end

    test "rejects a field that is not filterable" do
      scope = user_scope_fixture()
      params = %{filters: %{"0" => %{field: "name", op: "==", value: "x"}}}

      assert {:error, %Flop.Meta{errors: [filters: [[field: [{"is invalid", _}]]]]}} =
               Tasks.list_tasks(scope, params)
    end

    test "rejects a value that is not a uuid" do
      scope = user_scope_fixture()

      assert {:error, %Flop.Meta{errors: [filters: [[value: [{"is invalid", _}]]]]}} =
               Tasks.list_tasks(scope, goal_filter("nope"))
    end

    test "ignores pagination and ordering params instead of applying them" do
      scope = user_scope_fixture()
      for _ <- 1..3, do: task_fixture(scope)

      assert {:ok, tasks} =
               Tasks.list_tasks(scope, %{page: 1, page_size: 1, order_by: ["name"]})

      assert length(tasks) == 3
    end

    test "counts each task's notes, reporting 0 rather than nil for a bare task" do
      scope = user_scope_fixture()
      with_notes = task_fixture(scope)
      bare = task_fixture(scope, %{name: "Bare"})
      task_note_fixture(scope, with_notes)
      task_note_fixture(scope, with_notes, %{title: "Second"})

      {:ok, tasks} = Tasks.list_tasks(scope)
      counts = Map.new(tasks, &{&1.id, &1.notes_count})

      assert counts == %{with_notes.id => 2, bare.id => 0}
    end

    # The only place the notes subquery and Flop's :goal join have to coexist.
    test "keeps notes_count under a goal filter" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
      task_note_fixture(scope, task)

      assert {:ok, [listed]} = Tasks.list_tasks(scope, goal_filter(goal.reference_xid))
      assert listed.notes_count == 1
    end

    test "public filter allowlist is exactly goal_reference_xid" do
      assert Flop.allowed_fields(:filterable, for: Task) == [:goal_reference_xid]
    end
  end

  describe "list_recommended/2" do
    test "returns only scheduled and in-progress tasks with a due date, soonest first" do
      scope = user_scope_fixture()
      later = task_fixture(scope, %{due_at: due_in(3)})
      sooner = task_fixture(scope, %{due_at: due_in(1), status: :in_progress})
      _no_due_date = task_fixture(scope, %{due_at: nil})
      _completed = task_fixture(scope, %{status: :completed})
      _dropped = task_fixture(scope, %{status: :dropped})
      _on_hold = task_fixture(scope, %{status: :on_hold})
      _other_user = task_fixture(user_scope_fixture())

      assert {:ok, {tasks, %Flop.Meta{}}} = Tasks.list_recommended(scope)
      assert Enum.map(tasks, & &1.id) == [sooner.id, later.id]
    end

    test "paginates with a cursor" do
      scope = user_scope_fixture()

      [task_1, task_2, task_3] =
        for days <- 1..3, do: task_fixture(scope, %{due_at: due_in(days)})

      assert {:ok, {page_1, meta}} = Tasks.list_recommended(scope, %{"first" => 2})
      assert Enum.map(page_1, & &1.id) == [task_1.id, task_2.id]
      assert meta.has_next_page?
      assert is_binary(meta.end_cursor)

      assert {:ok, {page_2, meta}} =
               Tasks.list_recommended(scope, %{"first" => 2, "after" => meta.end_cursor})

      assert Enum.map(page_2, & &1.id) == [task_3.id]
      refute meta.has_next_page?
    end

    test "ignores client-supplied ordering and filters" do
      scope = user_scope_fixture()
      z_sooner = task_fixture(scope, %{name: "Z", due_at: due_in(1)})
      a_later = task_fixture(scope, %{name: "A", due_at: due_in(2)})

      params = %{
        "order_by" => ["name"],
        "filters" => %{
          "0" => %{"field" => "goal_reference_xid", "op" => "empty", "value" => false}
        }
      }

      assert {:ok, {tasks, _meta}} = Tasks.list_recommended(scope, params)
      assert Enum.map(tasks, & &1.id) == [z_sooner.id, a_later.id]
    end

    test "rejects a page size above the maximum" do
      scope = user_scope_fixture()

      assert {:error, %Flop.Meta{errors: [first: [_message]]}} =
               Tasks.list_recommended(scope, %{"first" => 51})
    end
  end

  describe "get_task!/2" do
    test "returns the scoped task by reference_xid" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      assert Tasks.get_task!(scope, task.reference_xid).id == task.id
    end

    test "agrees with list_tasks/3 on notes_count" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      task_note_fixture(scope, task)

      assert Tasks.get_task!(scope, task.reference_xid).notes_count == 1
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

  describe "create_task/2 under a parent" do
    test "inherits the parent's goal and sets the parent when no goal is sent" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      parent = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})

      assert {:ok, child} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: parent.reference_xid
               })

      assert child.parent_id == parent.id
      assert child.goal_id == parent.goal_id
    end

    test "inherits a nil goal from a goal-less parent" do
      scope = user_scope_fixture()
      parent = task_fixture(scope)

      assert {:ok, child} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: parent.reference_xid
               })

      assert child.goal_id == nil
    end

    test "accepts a goal_reference_xid equal to the parent's" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      parent = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})

      assert {:ok, _child} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: parent.reference_xid,
                 goal_reference_xid: goal.reference_xid
               })
    end

    test "rejects a goal_reference_xid that differs from the parent's" do
      scope = user_scope_fixture()
      parent_goal = goal_fixture(scope)
      other_goal = goal_fixture(scope)
      parent = task_fixture(scope, %{goal_reference_xid: parent_goal.reference_xid})

      assert {:error, cs} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: parent.reference_xid,
                 goal_reference_xid: other_goal.reference_xid
               })

      assert %{
               goal_reference_xid: [
                 "must match the parent's goal; a child inherits its parent's goal"
               ]
             } = errors_on(cs)
    end

    test "rejects an unknown parent_reference_xid" do
      scope = user_scope_fixture()

      assert {:error, cs} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: Ecto.UUID.generate()
               })

      assert %{parent_reference_xid: ["does not exist"]} = errors_on(cs)
    end

    test "hides another user's task when used as a parent" do
      scope = user_scope_fixture()
      other_parent = task_fixture(user_scope_fixture())

      assert {:error, cs} =
               Tasks.create_task(scope, %{
                 name: "child",
                 parent_reference_xid: other_parent.reference_xid
               })

      assert %{parent_reference_xid: ["does not exist"]} = errors_on(cs)
    end
  end

  describe "list_children/3" do
    test "returns only the parent's direct children" do
      scope = user_scope_fixture()
      parent = task_fixture(scope)
      child_a = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})
      child_b = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})
      _grandchild = task_fixture(scope, %{parent_reference_xid: child_a.reference_xid})
      _unrelated = task_fixture(scope)

      ids = scope |> Tasks.list_children(parent) |> Enum.map(& &1.id) |> Enum.sort()
      assert ids == Enum.sort([child_a.id, child_b.id])
    end

    test "excludes children when the caller does not own the parent" do
      owner = user_scope_fixture()
      intruder = user_scope_fixture()
      parent = task_fixture(owner)
      _child = task_fixture(owner, %{parent_reference_xid: parent.reference_xid})

      assert Tasks.list_children(intruder, parent) == []
    end

    test "returns an empty list when the task has no children" do
      scope = user_scope_fixture()
      parent = task_fixture(scope)
      assert Tasks.list_children(scope, parent) == []
    end
  end

  describe "subtree deletion" do
    test "deleting a parent deletes its descendants at every level" do
      scope = user_scope_fixture()
      root = task_fixture(scope)
      child = task_fixture(scope, %{parent_reference_xid: root.reference_xid})
      grandchild = task_fixture(scope, %{parent_reference_xid: child.reference_xid})

      assert {:ok, _} = Tasks.delete_task(scope, root)

      for t <- [root, child, grandchild] do
        assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, t.reference_xid) end
      end
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

    test "updates status" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, updated} = Tasks.update_task(scope, task, %{status: :completed})
      assert updated.status == :completed
    end

    test "with an unknown status errors and leaves the row unchanged" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Tasks.update_task(scope, task, %{status: :abandoned})

      assert "is invalid" in errors_on(changeset).status
      assert Tasks.get_task!(scope, task.reference_xid).status == task.status
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

  test "deleting a goal also deletes child tasks under an attached parent" do
    scope = user_scope_fixture()
    goal = goal_fixture(scope)
    parent = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
    child = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})

    assert {:ok, _} = Brekitdown.Goals.delete_goal(scope, goal)
    assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, parent.reference_xid) end
    assert_raise Ecto.NoResultsError, fn -> Tasks.get_task!(scope, child.reference_xid) end
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

  defp due_in(days) do
    DateTime.utc_now() |> DateTime.add(days, :day) |> DateTime.truncate(:second)
  end

  defp goal_filter(reference_xid) do
    %{filters: %{"0" => %{field: "goal_reference_xid", op: "==", value: reference_xid}}}
  end
end
