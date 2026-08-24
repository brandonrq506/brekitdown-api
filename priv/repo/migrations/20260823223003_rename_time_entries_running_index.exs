defmodule Brekitdown.Repo.Migrations.RenameTimeEntriesRunningIndex do
  use Ecto.Migration

  # Vocabulary only: the entry vocabulary is running/finished everywhere else, including the
  # `entry_already_running` conflict code this index backstops. Renaming an index rewrites no
  # rows and takes no meaningful lock.
  def change do
    execute(
      "ALTER INDEX time_entries_one_open_per_task_index RENAME TO time_entries_one_running_per_task_index",
      "ALTER INDEX time_entries_one_running_per_task_index RENAME TO time_entries_one_open_per_task_index"
    )
  end
end
