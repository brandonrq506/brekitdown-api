defmodule BrekitdownWeb.RecommendationController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Tasks
  alias BrekitdownWeb.Schemas.{ChangesetError, Error, RecommendationsResponse}
  alias OpenApiSpex.Schema

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["recommendations"])

  operation(:index,
    summary: "Tasks the current user should work on next",
    description:
      "Scheduled and in-progress tasks with a due date, soonest first. Cursor-paginated.",
    security: [%{"bearer" => []}],
    parameters: [
      first: [
        in: :query,
        description: "Page size",
        schema: %Schema{type: :integer, minimum: 1, maximum: 50, default: 20}
      ],
      after: [
        in: :query,
        description: "Cursor from a previous response's meta.end_cursor",
        schema: %Schema{type: :string}
      ]
    ],
    responses: [
      ok: {"Recommended tasks", "application/json", RecommendationsResponse},
      unprocessable_entity: {"Invalid query parameters", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, params) do
    with {:ok, {tasks, flop_meta}} <- Tasks.list_recommended(conn.assigns.current_scope, params) do
      render(conn, :index, tasks: tasks, flop_meta: flop_meta)
    end
  end
end
