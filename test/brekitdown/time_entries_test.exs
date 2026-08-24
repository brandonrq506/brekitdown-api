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
    test "creates a running entry" do
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

    test "rejects a second running entry on the same task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      _running = time_entry_fixture(scope, task, %{ended_at: nil})

      assert {:error, :entry_already_running} =
               TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(1)})
    end

    test "allows a finished entry while another entry is running on the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      _running = time_entry_fixture(scope, task, %{ended_at: nil})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, task, %{
                 started_at: hours_ago(5),
                 ended_at: hours_ago(4)
               })
    end

    test "allows a running entry on each of two different tasks" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert {:ok, %TimeEntry{}} =
               TimeEntries.create_time_entry(scope, other_task, %{started_at: hours_ago(2)})
    end

    test "a running entry starts a scheduled task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      {:ok, _entry} = TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "a running entry puts a completed task back in progress" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :completed})

      {:ok, _entry} = TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "a running entry puts a dropped task back in progress" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :dropped})

      {:ok, _entry} = TimeEntries.create_time_entry(scope, task, %{started_at: hours_ago(2)})

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "a finished entry starts a scheduled task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)

      _entry = time_entry_fixture(scope, task)

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "a finished entry leaves a dropped task dropped" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :dropped})

      _entry = time_entry_fixture(scope, task)

      assert Tasks.get_task!(scope, task.reference_xid).status == :dropped
    end

    test "a finished entry leaves a completed task completed" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :completed})

      _entry = time_entry_fixture(scope, task)

      assert Tasks.get_task!(scope, task.reference_xid).status == :completed
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

  describe ":time_entries_one_running_per_task_index" do
    # The context's 409 guard normally wins the race, so nothing else reaches the index.
    # This goes around the guard to prove the constraint name the schema declares still
    # matches the one the database holds — the only way renaming either breaks quietly.
    test "reports a second running entry through the changeset instead of raising" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      attrs = %{started_at: hours_ago(2)}

      {:ok, _entry} = Repo.insert(TimeEntry.create_changeset(%TimeEntry{}, attrs, scope, task))

      assert {:error, changeset} =
               Repo.insert(TimeEntry.create_changeset(%TimeEntry{}, attrs, scope, task))

      assert %{task_id: [_ | _]} = errors_on(changeset)
    end
  end

  describe "update_time_entry/4" do
    test "stops a running entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task, %{ended_at: nil})
      ended_at = DateTime.utc_now(:second)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, task, entry, %{ended_at: ended_at})

      assert updated.ended_at == ended_at
      assert updated.started_at == entry.started_at
    end

    test "un-stops a finished entry" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, task, entry, %{ended_at: nil})

      assert updated.ended_at == nil
    end

    test "rejects un-stopping when another entry is already running on the task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      finished = time_entry_fixture(scope, task)

      _running =
        time_entry_fixture(scope, task, %{started_at: DateTime.utc_now(:second), ended_at: nil})

      assert {:error, :entry_already_running} =
               TimeEntries.update_time_entry(scope, task, finished, %{ended_at: nil})
    end

    test "edits started_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)
      started_at = hours_ago(3)

      assert {:ok, %TimeEntry{} = updated} =
               TimeEntries.update_time_entry(scope, task, entry, %{started_at: started_at})

      assert updated.started_at == started_at
      assert updated.ended_at == entry.ended_at
    end

    test "rejects a started_at later than the stored ended_at" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert {:error, changeset} =
               TimeEntries.update_time_entry(scope, task, entry, %{
                 started_at: DateTime.utc_now(:second)
               })

      assert %{ended_at: ["must not be before started_at"]} = errors_on(changeset)
    end

    test "stopping an entry leaves the task in progress" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task, %{ended_at: nil})

      # The fixture's running entry already started the task; refetch so the rule below
      # runs against the status the database holds, not the one task_fixture returned.
      task = Tasks.get_task!(scope, task.reference_xid)
      assert task.status == :in_progress

      {:ok, _} =
        TimeEntries.update_time_entry(scope, task, entry, %{ended_at: DateTime.utc_now(:second)})

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "un-stopping an entry puts a completed task back in progress" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :completed})
      entry = time_entry_fixture(scope, task)

      {:ok, _} = TimeEntries.update_time_entry(scope, task, entry, %{ended_at: nil})

      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "correcting a finished entry's timestamps leaves a dropped task dropped" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :dropped})
      entry = time_entry_fixture(scope, task)

      {:ok, _} = TimeEntries.update_time_entry(scope, task, entry, %{started_at: hours_ago(3)})

      assert Tasks.get_task!(scope, task.reference_xid).status == :dropped
    end

    test "raises for another user's entry" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.update_time_entry(other_scope, task, entry, %{ended_at: nil})
      end
    end

    test "raises when the entry belongs to another task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.update_time_entry(scope, other_task, entry, %{ended_at: nil})
      end
    end
  end

  describe "delete_time_entry/3" do
    test "deletes the entry and leaves the task's other entries alone" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      kept = time_entry_fixture(scope, task, %{started_at: hours_ago(5), ended_at: hours_ago(4)})
      doomed = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, task, doomed)

      assert TimeEntries.list_time_entries_by_task(scope, task) == [kept]
    end

    test "resets an in_progress task to scheduled when no entries remain" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :in_progress})
      entry = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, task, entry)

      assert TimeEntries.list_time_entries_by_task(scope, task) == []
      assert Tasks.get_task!(scope, task.reference_xid).status == :scheduled
    end

    test "keeps an in_progress task in progress while entries remain" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :in_progress})
      kept = time_entry_fixture(scope, task, %{started_at: hours_ago(5), ended_at: hours_ago(4)})
      doomed = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, task, doomed)

      assert TimeEntries.list_time_entries_by_task(scope, task) == [kept]
      assert Tasks.get_task!(scope, task.reference_xid).status == :in_progress
    end

    test "leaves a completed task completed when no entries remain" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :completed})
      entry = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, task, entry)

      assert Tasks.get_task!(scope, task.reference_xid).status == :completed
    end

    test "leaves a dropped task dropped when no entries remain" do
      scope = user_scope_fixture()
      task = task_fixture(scope, %{status: :dropped})
      entry = time_entry_fixture(scope, task)

      assert {:ok, %TimeEntry{}} = TimeEntries.delete_time_entry(scope, task, entry)

      assert Tasks.get_task!(scope, task.reference_xid).status == :dropped
    end

    test "raises for another user's entry" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      task = task_fixture(scope)
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.delete_time_entry(other_scope, task, entry)
      end
    end

    test "raises when the entry belongs to another task" do
      scope = user_scope_fixture()
      task = task_fixture(scope)
      other_task = task_fixture(scope, %{name: "Other task"})
      entry = time_entry_fixture(scope, task)

      assert_raise MatchError, fn ->
        TimeEntries.delete_time_entry(scope, other_task, entry)
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
