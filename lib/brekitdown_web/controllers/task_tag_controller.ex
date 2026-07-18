defmodule BrekitdownWeb.TaskTagController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Tasks

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    Error,
    TaskResponse,
    TaskTagCreateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["tasks"])

  operation(:create,
    summary: "Attach a tag to a task",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [
        in: :path,
        type: :string,
        required: true,
        description: "The task's reference_xid"
      ]
    ],
    request_body: {"Tag attributes", "application/json", TaskTagCreateRequest},
    responses: [
      ok: {"The task with its tags", "application/json", TaskResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Task not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, %{task_id: task_xid}) do
    %TaskTagCreateRequest{name: name} = OpenApiSpex.body_params(conn)
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    with {:ok, task} <- Tasks.attach_tag(scope, task, name, [:goal, :tags]) do
      conn
      |> put_view(BrekitdownWeb.TaskJSON)
      |> render(:show, task: task)
    end
  end

  operation(:delete,
    summary: "Detach a tag from a task",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, required: true, description: "The task's reference_xid"],
      id: [in: :path, type: :string, required: true, description: "The tag's reference_xid"]
    ],
    responses: [
      no_content: "Tag detached",
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{task_id: task_xid, id: tag_xid}) do
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    with :ok <- Tasks.detach_tag(scope, task, tag_xid) do
      send_resp(conn, :no_content, "")
    end
  end
end
