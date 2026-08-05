defmodule Brekitdown.TimeEntriesTest do
  use Brekitdown.DataCase

  alias Brekitdown.Tasks
  alias Brekitdown.TimeEntries
  alias Brekitdown.TimeEntries.TimeEntry

  import Brekitdown.AccountsFixtures, only: [user_scope_fixture: 0]
  import Brekitdown.TasksFixtures
  import Brekitdown.TimeEntriesFixtures

  defp hours_ago(hours), do: DateTime.utc_now(:second) |> DateTime.shift(hour: -hours)

  describe "create_time_entry/3" do
    test "creates an open entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      started_at = hours_ago(2)

      assert {:ok, %TimeEntry{} = entry} =
               TimeEntries.create_time_entry(scope, task, %{started_at: started_at})

      assert entry.started_at == started_at
      assert entry.ended_at == nil
      assert entry.task_id == task.id
      assert entry.user_id == scope.user.id
      assert entry.reference_xid
    end

    test "creates a retroactive finished entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      started_at = hours_ago(5)
      ended_at = hours_ago(4)

      assert {:ok, %TimeEntry{} = entry} =
               TimeEntries.create_time_entry(scope, task, %{
                 started_at: started_at,
                 ended_at: ended_at
               })

      assert entry.started_at == started_at
      assert entry.ended_at == ended_at
    end

    test "requires started_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, changeset} = TimeEntries.create_time_entry(scope, task, %{})
      assert %{started_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects ended_at before started_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      assert {:error, changeset} =
               TimeEntries.create_time_entry(scope, task, %{
                 started_at: hours_ago(1),
                 ended_at: hours_ago(2)
               })

      assert %{ended_at: ["must not be before started_at"]} = errors_on(changeset)
    end

    test "accepts a same-second start and end" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      at = hours_ago(1)

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, task, %{started_at: at, ended_at: at})
    end

    test "rejects a task that has subtasks" do
      scope = user_scope_fixture()
      parent = task_fixture(scope)
      _child = task_fixture(scope, %{parent_reference_xid: parent.reference_xid})

      assert {:error, :not_a_leaf_task} =
               TimeEntries.create_time_entry(scope, parent, %{started_at: hours_ago(2)})
    end

    test "rejects a second open entry on the same task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      _open = time_entry_fixture(scope, task, %{ended_at: nil})

      assert {:error, :entry_already_running} =
               TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(1)})
    end

    test "allows a finished entry while another entry is open on the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      _open = time_entry_fixture(scope, task, %{ended_at: nil})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, task, %{
                 started_at: hours_ago(5),
                 ended_at: hours_ago(4)
               })
    end

    test "allows an open entry on each of two different tasks" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, other_task, %{started_at: hours_ago(2)})
    end

    test "leaves the task's status untouched" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      {:ok, _entry} = TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert Tasks.get_task!(scope, task.reference_xid).status == task.status
    end

    test "raises for a task owned by another user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)

      assert_raise MatchError, fn ->
        TimeEntries.create_time_entry(other_scope, task, %{started_at: hours_ago(2)})
      end
    end
  end

  describe "update_time_entry/3" do
    test "stops an open entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task, %{ended_at: nil})
      ended_at = DateTime.utc_now(:second)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, entry, %{ended_at: ended_at})

      assert updated.ended_at == ended_at
      assert updated.started_at == entry.started_at
    end

    test "un-stops a finished entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, entry, %{ended_at: nil})

      assert updated.ended_at == nil
    end

    test "rejects un-stopping when another entry is already open on the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      finished = time_entry_fixture(scope, task)

      _open =
        time_entry_fixture(scope, task, %{started_at: DateTime.utc_now(:second), ended_at: nil})

      assert {:error, :entry_already_running} =
               TimeEntries.update_time_entry(scope, finished, %{ended_at: nil})
    end

    test "edits started_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)
      started_at = hours_ago(3)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, entry, %{started_at: started_at})

      assert updated.started_at == started_at
      assert updated.ended_at == entry.ended_at
    end

    test "rejects a started_at later than the stored ended_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert {:error, changeset} =
               TimeEntries.update_time_entry(scope, entry, %{
                 started_at: DateTime.utc_now(:second)
               })

      assert %{ended_at: ["must not be before started_at"]} = errors_on(changeset)
    end

    test "leaves the task's status untouched" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task, %{ended_at: nil})

      {:ok, _} =
        TimeEntries.update_time_entry(scope, entry, %{ended_at: DateTime.utc_now(:second)})

      assert Tasks.get_task!(scope, task.reference_xid).status == task.status
    end

    test "raises for another user's entry" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.update_time_entry(other_scope, entry, %{ended_at: nil})
      end
    end
  end

  describe "delete_time_entry/2" do
    test "deletes the entry and leaves the task's other entries alone" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      kept = time_entry_fixture(scope, task, %{started_at: hours_ago(5), ended_at: hours_ago(4)})
      doomed = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, doomed)

      assert TimeEntries.list_time_entries_by_task(scope, task) == [kept]
    end

    test "leaves the task's status untouched" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      {:ok, _} = TimeEntries.delete_time_entry(scope, entry)

      assert Tasks.get_task!(scope, task.reference_xid).status == task.status
    end

    test "raises for another user's entry" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.delete_time_entry(other_scope, entry)
      end
    end
  end

  describe "list_time_entries_by_task/2" do
    test "returns the task's entries ordered by started_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      recent = time_entry_fixture(scope, task)
      older = time_entry_fixture(scope, task, %{started_at: hours_ago(5), ended_at: hours_ago(4)})

      assert TimeEntries.list_time_entries_by_task(scope, task) == [older, recent]
    end

    test "excludes entries belonging to another task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      entry = time_entry_fixture(scope, task)
      _other_entry = time_entry_fixture(scope, other_task)

      assert TimeEntries.list_time_entries_by_task(scope, task) == [entry]
    end

    test "returns nothing for another user's scope" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      _entry = time_entry_fixture(scope, task)

      assert TimeEntries.list_time_entries_by_task(other_scope, task) == []
    end

    test "returns an empty list when the task has no entries" do
      scope = user_scope_fixture()

      assert TimeEntries.list_time_entries_by_task(scope, task_fixture(scope)) == []
    end
  end

  describe "get_time_entry/3 and get_time_entry!/3" do
    test "get_time_entry/3 returns the entry for its owner and nil for another user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert TimeEntries.get_time_entry(scope, task, entry.reference_xid) == entry
      assert TimeEntries.get_time_entry(other_scope, task, entry.reference_xid) == nil
    end

    test "get_time_entry!/3 returns the entry by reference_xid" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert TimeEntries.get_time_entry!(scope, task, entry.reference_xid) == entry
    end

    test "get_time_entry!/3 raises for an entry owned by another user" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert_raise Ecto.NoResultsError, fn ->
        TimeEntries.get_time_entry!(other_scope, task, entry.reference_xid)
      end
    end

    test "get_time_entry!/3 raises for the right entry under the wrong task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      entry = time_entry_fixture(scope, task)

      assert_raise Ecto.NoResultsError, fn ->
        TimeEntries.get_time_entry!(scope, other_task, entry.reference_xid)
      end
    end
  end

  describe "task_has_entries?/1" do
    test "is true only once the task has an entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      refute TimeEntries.task_has_entries?(task)

      _entry = time_entry_fixture(scope, task)

      assert TimeEntries.task_has_entries?(task)
    end
  end

  test "deleting the task cascades its time entries" do
    scope = user_scope_fixture()
    task = task_fixture(scope)
    _entry = time_entry_fixture(scope, task)

    {:ok, _task} = Tasks.delete_task(scope, task)

    assert Repo.aggregate(TimeEntry, :count) == 0
  end
end
