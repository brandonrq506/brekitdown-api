defmodule BrekitdownWeb.UserController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias BrekitdownWeb.Schemas.{UserResponse, Error}

  tags(["users"])

  operation(:me,
    summary: "Get the current user",
    description: "Returns the user resolved from the bearer token.",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"The current user", "application/json", UserResponse},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  @spec me(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def me(conn, _params) do
    conn
    |> put_view(json: BrekitdownWeb.UserJSON)
    |> render(:user, user: conn.assigns.current_scope.user)
  end
end
