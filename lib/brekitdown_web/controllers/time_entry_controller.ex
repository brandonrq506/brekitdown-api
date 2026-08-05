defmodule BrekitdownWeb.TimeEntryController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Tasks
  alias Brekitdown.TimeEntries
  alias Brekitdown.TimeEntries.TimeEntry

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    ConflictError,
    Error,
    TimeEntriesResponse,
    TimeEntryCreateRequest,
    TimeEntryResponse,
    TimeEntryUpdateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["time_entries"])

  operation(:index,
    summary: "List a task's time entries",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, description: "The task's reference_xid"]
    ],
    responses: [
      ok: {"The task's time entries", "application/json", TimeEntriesResponse},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, %{task_id: task_xid}) do
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    render(conn, :index, time_entries: TimeEntries.list_time_entries_by_task(scope, task))
  end

  operation(:create,
    summary: "Create a time entry for a task",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, description: "The task's reference_xid"]
    ],
    request_body: {"Time entry attributes", "application/json", TimeEntryCreateRequest},
    responses: [
      created: {"Time entry created", "application/json", TimeEntryResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      conflict: {"The task's state forbids this", "application/json", ConflictError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, %{task_id: task_xid}) do
    %TimeEntryCreateRequest{time_entry: time_entry_params} = OpenApiSpex.body_params(conn)

    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)

    with {:ok, %TimeEntry{} = time_entry} <-
           TimeEntries.create_time_entry(scope, task, time_entry_params) do
      conn
      |> put_status(:created)
      |> render(:show, time_entry: time_entry)
    end
  end

  operation(:update,
    summary: "Update a time entry",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, required: true, description: "The task's reference_xid"],
      id: [
        in: :path,
        type: :string,
        required: true,
        description: "The time entry's reference_xid"
      ]
    ],
    request_body: {"Time entry params", "application/json", TimeEntryUpdateRequest},
    responses: [
      ok: {"Time entry updated", "application/json", TimeEntryResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      conflict: {"The task's state forbids this", "application/json", ConflictError},
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def update(conn, %{task_id: task_xid, id: time_entry_id}) do
    %TimeEntryUpdateRequest{time_entry: time_entry_params} = OpenApiSpex.body_params(conn)

    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)
    time_entry = TimeEntries.get_time_entry!(scope, task, time_entry_id)

    with {:ok, %TimeEntry{} = time_entry} <-
           TimeEntries.update_time_entry(scope, time_entry, time_entry_params) do
      render(conn, :show, time_entry: time_entry)
    end
  end

  operation(:delete,
    summary: "Delete a time entry",
    security: [%{"bearer" => []}],
    parameters: [
      task_id: [in: :path, type: :string, required: true, description: "The task's reference_xid"],
      id: [
        in: :path,
        type: :string,
        required: true,
        description: "The time entry's reference_xid"
      ]
    ],
    responses: [
      no_content: "Time entry deleted",
      not_found: {"Not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{task_id: task_xid, id: time_entry_xid}) do
    scope = conn.assigns.current_scope
    task = Tasks.get_task!(scope, task_xid)
    time_entry = TimeEntries.get_time_entry!(scope, task, time_entry_xid)

    with {:ok, %TimeEntry{}} <- TimeEntries.delete_time_entry(scope, time_entry) do
      send_resp(conn, :no_content, "")
    end
  end
end
