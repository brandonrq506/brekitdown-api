defmodule Brekitdown.Repo.Migrations.CreateTasksTags do
  use Ecto.Migration

  def change do
    create table(:tasks_tags, primary_key: false) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false, primary_key: true
      add :tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:tasks_tags, [:tag_id, :task_id])
  end
end
