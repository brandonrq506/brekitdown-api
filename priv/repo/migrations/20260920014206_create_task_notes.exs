defmodule Brekitdown.Repo.Migrations.CreateTaskNotes do
  use Ecto.Migration

  def change do
    create table(:task_notes) do
      add :title, :string, null: false, default: ""
      add :body, :text, null: false, default: ""
      add :reference_xid, :uuid, null: false, default: fragment("uuidv7()")
      add :task_id, references(:tasks, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:task_notes, [:reference_xid])
    create index(:task_notes, [:task_id])
  end
end
