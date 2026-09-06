defmodule BrekitdownWeb.TaskController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Repo
  alias Brekitdown.Tasks
  alias Brekitdown.Tasks.Task

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    Error,
    TaskCreateRequest,
    TaskFilters,
    TaskResponse,
    TasksResponse,
    TaskUpdateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["tasks"])

  operation(:index,
    summary: "List the current user's tasks",
    description: "Optionally accepts filters. Supported: goal_reference_xid",
    security: [%{"bearer" => []}],
    parameters: [
      filters: [
        in: :query,
        style: :deepObject,
        explode: true,
        schema: TaskFilters
      ]
    ],
    responses: [
      ok: {"The user's tasks", "application/json", TasksResponse},
      unprocessable_entity: {"Invalid query parameters", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, params) do
    with {:ok, tasks} <-
           Tasks.list_tasks(conn.assigns.current_scope, params, [:goal, :tags, :parent]) do
      render(conn, :index, tasks: tasks)
    end
  end

  operation(:create,
    summary: "Create a task",
    security: [%{"bearer" => []}],
    request_body: {"Task attributes", "application/json", TaskCreateRequest},
    responses: [
      created: {"Task created", "application/json", TaskResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, _params) do
    %TaskCreateRequest{task: task_params} = OpenApiSpex.body_params(conn)

    with {:ok, %Task{} = task} <- Tasks.create_task(conn.assigns.current_scope, task_params) do
      conn
      |> put_status(:created)
      |> render(:show, task: Repo.preload(task, [:goal, :tags, :parent]))
    end
  end

  operation(:show,
    summary: "Get a task by reference_xid",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The task's reference_xid"]
    ],
    responses: [
      ok: {"The task", "application/json", TaskResponse},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def show(conn, %{id: id}) do
    task = Tasks.get_task!(conn.assigns.current_scope, id, [:goal, :tags, :parent])
    render(conn, :show, task: task)
  end

  operation(:update,
    summary: "Update a task",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The task's reference_xid"]
    ],
    request_body: {"Task params", "application/json", TaskUpdateRequest},
    responses: [
      ok: {"Task updated", "application/json", TaskResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def update(conn, %{id: id}) do
    %TaskUpdateRequest{task: task_params} = OpenApiSpex.body_params(conn)

    task = Tasks.get_task!(conn.assigns.current_scope, id, [:goal, :tags, :parent])

    with {:ok, %Task{} = task} <- Tasks.update_task(conn.assigns.current_scope, task, task_params) do
      render(conn, :show, task: task)
    end
  end

  operation(:delete,
    summary: "Delete a task",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The task's reference_xid"]
    ],
    responses: [
      no_content: "Task deleted",
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{id: id}) do
    task = Tasks.get_task!(conn.assigns.current_scope, id, [:goal, :tags, :parent])

    with {:ok, %Task{}} <- Tasks.delete_task(conn.assigns.current_scope, task) do
      send_resp(conn, :no_content, "")
    end
  end
end
