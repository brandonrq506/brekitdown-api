defmodule BrekitdownWeb.UserRegistrationController do
  use BrekitdownWeb, :controller

  alias Brekitdown.Accounts

  action_fallback BrekitdownWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.register_user(user_params) do
      token =
        user
        |> Accounts.generate_user_session_token()
        |> encode()

      conn
      |> put_status(:created)
      |> put_view(json: BrekitdownWeb.UserJSON)
      |> render(:user_with_token, user: user, token: token)
    end
  end

  defp encode(raw), do: Base.url_encode64(raw, padding: false)
end
