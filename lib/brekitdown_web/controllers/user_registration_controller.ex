defmodule BrekitdownWeb.UserRegistrationController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias BrekitdownWeb.Schemas.{RegisterRequest, UserWithToken, ChangesetError}
  alias Brekitdown.Accounts

  action_fallback BrekitdownWeb.FallbackController

  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["users"])

  operation(:create,
    summary: "Register a new user",
    request_body: {"Registration params", "application/json", RegisterRequest},
    responses: [
      created: {"User created with a session token", "application/json", UserWithToken},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError}
    ]
  )

  def create(conn, _params) do
    %RegisterRequest{user: user_params} = OpenApiSpex.body_params(conn)

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
