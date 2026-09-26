defmodule Brekitdown.Repo.Migrations.AddTasksRecommendationIndex do
  use Ecto.Migration

  def change do
    create index(:tasks, [:user_id, :due_at, :id],
             where: "due_at IS NOT NULL",
             name: :tasks_user_due_at_recommendation_idx
           )
  end
end
