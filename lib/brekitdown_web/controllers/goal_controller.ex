defmodule BrekitdownWeb.GoalController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Goals
  alias Brekitdown.Goals.Goal
  alias OpenApiSpex.Schema

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    Error,
    GoalCreateRequest,
    GoalResponse,
    GoalsResponse,
    GoalUpdateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["goals"])

  operation(:index,
    summary: "List the current user's goals",
    security: [%{"bearer" => []}],
    parameters: [
      page: [
        in: :query,
        description: "Page number",
        schema: %Schema{type: :integer, minimum: 1, default: 1}
      ],
      page_size: [
        in: :query,
        description: "Number of goals per page",
        schema: %Schema{
          type: :integer,
          enum: Goal.page_sizes(),
          default: Flop.Schema.default_limit(%Goal{}),
          maximum: Flop.Schema.max_limit(%Goal{})
        }
      ]
    ],
    responses: [
      ok: {"The user's goals", "application/json", GoalsResponse},
      unprocessable_entity: {"Invalid query parameters", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, params) do
    with {:ok, {goals, flop_meta}} <-
           Goals.paginated_list(conn.assigns.current_scope, params) do
      render(conn, :index, %{goals: goals, flop_meta: flop_meta})
    end
  end

  operation(:create,
    summary: "Create a goal",
    security: [%{"bearer" => []}],
    request_body: {"Goal attributes", "application/json", GoalCreateRequest},
    responses: [
      created: {"Goal created", "application/json", GoalResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, _params) do
    %GoalCreateRequest{goal: goal_params} = OpenApiSpex.body_params(conn)

    with {:ok, %Goal{} = goal} <- Goals.create_goal(conn.assigns.current_scope, goal_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/goals/#{goal}")
      |> render(:show, goal: goal)
    end
  end

  operation(:show,
    summary: "Get a goal by reference_xid",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The goal's reference_xid"]
    ],
    responses: [
      ok: {"The goal", "application/json", GoalResponse},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def show(conn, %{id: id}) do
    goal = Goals.get_goal!(conn.assigns.current_scope, id)
    render(conn, :show, goal: goal)
  end

  operation(:update,
    summary: "Update a goal",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "Goal reference_xid"]
    ],
    request_body: {"Goal params", "application/json", GoalUpdateRequest},
    responses: [
      ok: {"Goal updated", "application/json", GoalResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def update(conn, %{id: id}) do
    %GoalUpdateRequest{goal: goal_params} = OpenApiSpex.body_params(conn)

    goal = Goals.get_goal!(conn.assigns.current_scope, id)

    with {:ok, %Goal{} = goal} <- Goals.update_goal(conn.assigns.current_scope, goal, goal_params) do
      render(conn, :show, goal: goal)
    end
  end

  operation(:delete,
    summary: "Delete a goal",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "Goal reference_xid"]
    ],
    responses: [
      no_content: "Goal deleted",
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{id: id}) do
    goal = Goals.get_goal!(conn.assigns.current_scope, id)

    with {:ok, %Goal{}} <- Goals.delete_goal(conn.assigns.current_scope, goal) do
      send_resp(conn, :no_content, "")
    end
  end
end
