defmodule Brekitdown.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :name, :string, null: false
      add :status, :string, null: false, default: "scheduled"
      add :due_at, :utc_datetime
      add :reference_xid, :uuid, null: false, default: fragment("uuidv7()")
      add :goal_id, references(:goals, on_delete: :delete_all)
      add :parent_id, references(:tasks, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tasks, [:reference_xid])
    create index(:tasks, [:user_id])

    create index(:tasks, [:goal_id])
    create index(:tasks, [:parent_id])
  end
end
