defmodule Brekitdown.TaskNotesTest do
  use Brekitdown.DataCase

  alias Brekitdown.Goals
  alias Brekitdown.TaskNotes
  alias Brekitdown.TaskNotes.TaskNote
  alias Brekitdown.Tasks

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.GoalsFixtures
  import Brekitdown.TaskNotesFixtures
  import Brekitdown.TasksFixtures

  describe "list_task_notes_by_task/2" do
    test "returns the task's notes newest first" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      # Both land in the same second: `timestamps(type: :utc_datetime)` truncates, so this
      # is the case the `desc: :id` tiebreak exists for.
      older = task_note_fixture(scope, task, %{title: "Older"})
      newer = task_note_fixture(scope, task, %{title: "Newer"})

      assert Enum.map(TaskNotes.list_task_notes_by_task(scope, task), & &1.id) ==
               [newer.id, older.id]
    end

    test "returns an empty list when the task has no notes" do
      scope = user_scope_fixture()

      assert TaskNotes.list_task_notes_by_task(scope, task_fixture(scope)) == []
    end

    test "excludes another task's notes" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      note = task_note_fixture(scope, task)
      _other_note = task_note_fixture(scope, other_task)

      assert [listed] = TaskNotes.list_task_notes_by_task(scope, task)
      assert listed.id == note.id
    end

    test "raises for a task the scope does not own" do
      scope = user_scope_fixture()
      other_task = task_fixture(user_scope_fixture())

      assert_raise MatchError, fn -> TaskNotes.list_task_notes_by_task(scope, other_task) end
    end
  end

  describe "get_task_note!/3" do
    test "returns the note" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      note = task_note_fixture(scope, task)

      assert TaskNotes.get_task_note!(scope, task, note.reference_xid).id == note.id
    end

    test "raises for the right note under the wrong task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      note = task_note_fixture(scope, task)

      assert_raise Ecto.NoResultsError, fn ->
        TaskNotes.get_task_note!(scope, other_task, note.reference_xid)
      end
    end

    test "raises for a task the scope does not own" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      other_task = task_fixture(other_scope)
      other_note = task_note_fixture(other_scope, other_task)

      assert_raise MatchError, fn ->
        TaskNotes.get_task_note!(scope, other_task, other_note.reference_xid)
      end
    end
  end

  describe "create_task_note/3" do
    test "attaches the note to the task and generates a reference_xid" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, %TaskNote{} = note} =
               TaskNotes.create_task_note(scope, task, %{title: "Stuck", body: "On auth."})

      assert note.task_id == task.id
      assert note.title == "Stuck"
      assert note.body == "On auth."
      assert {:ok, _} = Ecto.UUID.cast(note.reference_xid)
    end

    test "trims surrounding whitespace off both fields" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, note} =
               TaskNotes.create_task_note(scope, task, %{title: "  Stuck  ", body: "  On auth.  "})

      assert note.title == "Stuck"
      assert note.body == "On auth."
    end

    test "requires a title and a body" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, changeset} = TaskNotes.create_task_note(scope, task, %{})

      assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects blank and whitespace-only values" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, blank} = TaskNotes.create_task_note(scope, task, %{title: "", body: ""})
      assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(blank)

      assert {:error, spaces} =
               TaskNotes.create_task_note(scope, task, %{title: "   ", body: "   "})

      assert %{title: ["can't be blank"], body: ["can't be blank"]} = errors_on(spaces)
    end

    test "accepts a 100-character title and a 5000-character body" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:ok, _note} =
               TaskNotes.create_task_note(scope, task, %{
                 title: String.duplicate("a", 100),
                 body: String.duplicate("b", 5000)
               })
    end

    test "rejects a title over 100 characters" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, changeset} =
               TaskNotes.create_task_note(scope, task, %{
                 title: String.duplicate("a", 101),
                 body: "On auth."
               })

      assert %{title: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "rejects a body over 5000 characters" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, changeset} =
               TaskNotes.create_task_note(scope, task, %{
                 title: "Stuck",
                 body: String.duplicate("b", 5001)
               })

      assert %{body: ["should be at most 5000 character(s)"]} = errors_on(changeset)
    end

    test "raises for a task the scope does not own" do
      scope = user_scope_fixture()
      other_task = task_fixture(user_scope_fixture())

      assert_raise MatchError, fn ->
        TaskNotes.create_task_note(scope, other_task, %{title: "Stuck", body: "On auth."})
      end
    end
  end

  describe "update_task_note/4" do
    test "updates the body and leaves the title alone" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      note = task_note_fixture(scope, task, %{title: "Stuck", body: "On auth."})

      assert {:ok, updated} = TaskNotes.update_task_note(scope, task, note, %{body: "Unstuck."})
      assert updated.body == "Unstuck."
      assert updated.title == "Stuck"
    end

    test "rejects blanking a field" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      note = task_note_fixture(scope, task)

      assert {:error, changeset} = TaskNotes.update_task_note(scope, task, note, %{body: "   "})
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end

    test "raises for a note belonging to another task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      note = task_note_fixture(scope, task)

      assert_raise MatchError, fn ->
        TaskNotes.update_task_note(scope, other_task, note, %{body: "Unstuck."})
      end
    end

    test "raises for a task the scope does not own" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      other_task = task_fixture(other_scope)
      other_note = task_note_fixture(other_scope, other_task)

      assert_raise MatchError, fn ->
        TaskNotes.update_task_note(scope, other_task, other_note, %{body: "Unstuck."})
      end
    end
  end

  describe "delete_task_note/3" do
    test "deletes the note" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      note = task_note_fixture(scope, task)

      assert {:ok, %TaskNote{}} = TaskNotes.delete_task_note(scope, task, note)
      assert TaskNotes.list_task_notes_by_task(scope, task) == []
    end

    test "raises for a note belonging to another task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      note = task_note_fixture(scope, task)

      assert_raise MatchError, fn -> TaskNotes.delete_task_note(scope, other_task, note) end
    end

    test "raises for a task the scope does not own" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      other_task = task_fixture(other_scope)
      other_note = task_note_fixture(other_scope, other_task)

      assert_raise MatchError, fn ->
        TaskNotes.delete_task_note(scope, other_task, other_note)
      end
    end
  end

  describe "cascading deletes" do
    test "deleting a task deletes its notes" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      note = task_note_fixture(scope, task)

      assert {:ok, _} = Tasks.delete_task(scope, task)
      refute Repo.get(TaskNote, note.id)
    end

    test "deleting a goal deletes its tasks' notes" do
      scope = user_scope_fixture()
      goal = goal_fixture(scope)
      task = task_fixture(scope, %{goal_reference_xid: goal.reference_xid})
      note = task_note_fixture(scope, task)

      assert {:ok, _} = Goals.delete_goal(scope, goal)
      refute Repo.get(TaskNote, note.id)
    end
  end
end
