defmodule BrekitdownWeb.FallbackController do
  use BrekitdownWeb, :controller

  require Logger

  # Catches {:error, changeset} from any action that declares this as action_fallback
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_content)
    |> put_view(BrekitdownWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, %Flop.Meta{} = meta}) do
    conn
    |> put_status(:unprocessable_content)
    |> put_view(BrekitdownWeb.FlopJSON)
    |> render(:error, meta: meta)
  end

  # Known business errors -> standardized %{errors: %{detail: ...}} via ErrorJSON
  def call(conn, {:error, :not_found}), do: render_error(conn, :not_found, :"404")
  def call(conn, {:error, :unauthorized}), do: render_error(conn, :unauthorized, :"401")
  def call(conn, {:error, :forbidden}), do: render_error(conn, :forbidden, :"403")
  def call(conn, {:error, :bad_request}), do: render_error(conn, :bad_request, :"400")

  def call(conn, {:error, :not_a_leaf_task}),
    do:
      render_conflict(
        conn,
        "not_a_leaf_task",
        "This task has subtasks, so time cannot be logged on it directly."
      )

  def call(conn, {:error, :entry_already_running}),
    do:
      render_conflict(
        conn,
        "entry_already_running",
        "This task already has a time entry that has not ended."
      )

  # Safety net: anything unmatched is logged and returned as a controlled 500.
  # The explicit clauses above always win, so this never changes how known errors format.
  def call(conn, {:error, reason}) do
    Logger.error("Unhandled error reached FallbackController: #{inspect(reason)}")
    render_error(conn, :internal_server_error, :"500")
  end

  defp render_error(conn, status, template) do
    conn
    |> put_status(status)
    |> put_view(BrekitdownWeb.ErrorJSON)
    |> render(template)
  end

  defp render_conflict(conn, code, detail) do
    conn
    |> put_status(:conflict)
    |> put_view(BrekitdownWeb.ErrorJSON)
    |> render(:"409", code: code, detail: detail)
  end
end
