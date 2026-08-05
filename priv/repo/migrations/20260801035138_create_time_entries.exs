defmodule Brekitdown.Repo.Migrations.CreateTimeEntries do
  use Ecto.Migration

  def change do
    create table(:time_entries) do
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime
      add :reference_xid, :uuid, null: false, default: fragment("uuidv7()")
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:time_entries, [:reference_xid])
    create index(:time_entries, [:user_id])
    create index(:time_entries, [:task_id])

    # At most one open timer per task.
    create unique_index(:time_entries, [:task_id],
             where: "ended_at IS NULL",
             name: :time_entries_one_open_per_task_index
           )

    # Corruption guard: an entry cannot end before it starts.
    create constraint(:time_entries, :time_entries_ended_at_after_started_at,
             check: "ended_at IS NULL OR ended_at >= started_at"
           )
  end
end
