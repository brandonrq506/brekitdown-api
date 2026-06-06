defmodule BrekitdownWeb.UserSessionController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Accounts
  alias BrekitdownWeb.Schemas.{LoginRequest, UserWithToken, Error}

  tags(["users"])

  operation(:create,
    summary: "Log in a user",
    request_body: {"Credentials", "application/json", LoginRequest},
    responses: [
      ok: {"User with a session token", "application/json", UserWithToken},
      unauthorized: {"Invalid email or password", "application/json", Error}
    ]
  )

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token =
        user
        |> Accounts.generate_user_session_token()
        |> encode()

      conn
      |> put_status(:ok)
      |> put_view(BrekitdownWeb.UserJSON)
      |> render(:user_with_token, user: user, token: token)
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: %{detail: "Invalid email or password"}})
    end
  end

  operation(:delete,
    summary: "Log out",
    security: [%{"bearer" => []}],
    responses: [no_content: "Logged out"]
  )

  def delete(conn, _params) do
    Accounts.delete_user_session_token(conn.assigns.user_token)
    send_resp(conn, :no_content, "")
  end

  defp encode(raw), do: Base.url_encode64(raw, padding: false)
end
