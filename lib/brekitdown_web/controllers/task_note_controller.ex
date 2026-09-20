defmodule BrekitdownWeb.TaskNoteController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.TaskNotes
  alias Brekitdown.TaskNotes.TaskNote
  alias Brekitdown.Tasks

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    Error,
    TaskNoteCreateRequest,
    TaskNoteResponse,
    TaskNotesResponse,
    TaskNoteUpdateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["task_notes"])

  operation(:index,
    summary: "List a task's notes",
    description: "Newest first.",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, description: "The task's reference_xid"]
    ],
    responses: [
      ok: {"The task's notes", "application/json", TaskNotesResponse},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, %{task_id: task_xid}) do
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    render(conn, :index, task_notes: TaskNotes.list_task_notes_by_task(scope, task))
  end

  operation(:create,
    summary: "Create a note on a task",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, description: "The task's reference_xid"]
    ],
    request_body: {"Note attributes", "application/json", TaskNoteCreateRequest},
    responses: [
      created: {"Note created", "application/json", TaskNoteResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, %{task_id: task_xid}) do
    %TaskNoteCreateRequest{note: note_params} = OpenApiSpex.body_params(conn)

    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    with {:ok, %TaskNote{} = task_note} <- TaskNotes.create_task_note(scope, task, note_params) do
      conn
      |> put_status(:created)
      |> render(:show, task_note: task_note)
    end
  end

  operation(:update,
    summary: "Update a note",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, required: true, description: "The task's reference_xid"],
      id: [in: :path, type: :string, required: true, description: "The note's reference_xid"]
    ],
    request_body: {"Note params", "application/json", TaskNoteUpdateRequest},
    responses: [
      ok: {"Note updated", "application/json", TaskNoteResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def update(conn, %{task_id: task_xid, id: note_xid}) do
    %TaskNoteUpdateRequest{note: note_params} = OpenApiSpex.body_params(conn)

    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)
    task_note = TaskNotes.get_task_note!(scope, task, note_xid)

    with {:ok, %TaskNote{} = task_note} <-
           TaskNotes.update_task_note(scope, task, task_note, note_params) do
      render(conn, :show, task_note: task_note)
    end
  end

  operation(:delete,
    summary: "Delete a note",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, required: true, description: "The task's reference_xid"],
      id: [in: :path, type: :string, required: true, description: "The note's reference_xid"]
    ],
    responses: [
      no_content: "Note deleted",
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{task_id: task_xid, id: note_xid}) do
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)
    task_note = TaskNotes.get_task_note!(scope, task, note_xid)

    with {:ok, %TaskNote{}} <- TaskNotes.delete_task_note(scope, task, task_note) do
      send_resp(conn, :no_content, "")
    end
  end
end
