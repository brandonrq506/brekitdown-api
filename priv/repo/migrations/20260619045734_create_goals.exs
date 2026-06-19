defmodule Brekitdown.Repo.Migrations.CreateGoals do
  use Ecto.Migration

  def change do
    create table(:goals) do
      add :name, :string, null: false
      add :description, :text
      add :reference_xid, :uuid, null: false, default: fragment("uuidv7()")
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goals, [:reference_xid])
    create index(:goals, [:user_id])
  end
end
