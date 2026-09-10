defmodule Brekitdown.Repo.Migrations.AddDescriptionToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :description, :text, null: false, default: ""
    end
  end
end
