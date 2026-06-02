defmodule BrekitdownWeb.FallbackController do
  use BrekitdownWeb, :controller

  # Catches {:error, changeset} from any action that declares this as action_fallback
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(BrekitdownWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end
end
