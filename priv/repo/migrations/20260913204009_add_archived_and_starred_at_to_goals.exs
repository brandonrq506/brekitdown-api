defmodule Brekitdown.Repo.Migrations.AddArchivedAndStarredAtToGoals do
  use Ecto.Migration

  def change do
    alter table(:goals) do
      add :archived_at, :utc_datetime
      add :starred_at, :utc_datetime
    end
  end
end
