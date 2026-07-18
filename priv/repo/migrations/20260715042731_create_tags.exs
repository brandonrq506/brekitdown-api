defmodule Brekitdown.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :citext, null: false
      add :reference_xid, :uuid, null: false, default: fragment("uuidv7()")
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:reference_xid])
    create unique_index(:tags, [:user_id, :name])
  end
end
