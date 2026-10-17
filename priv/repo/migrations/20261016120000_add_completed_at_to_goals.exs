defmodule Brekitdown.Repo.Migrations.AddCompletedAtToGoals do
  use Ecto.Migration

  def change do
    alter table(:goals) do
      add :completed_at, :utc_datetime
    end
  end
end
