defmodule BrekitdownWeb.UserJSON do
  alias Brekitdown.Accounts.User

  @doc "Just the user (for GET /users/me)"
  def user(%{user: user}), do: %{user: data(user)}

  @doc "User + freshly minted bearer token (for register / log-in)."
  def user_with_token(%{user: user, token: token}) do
    %{user: data(user), token: token}
  end

  # Never id or hadshed_password.
  defp data(%User{} = user) do
    %{
      reference_xid: user.reference_xid,
      email: user.email,
      inserted_at: user.inserted_at,
      confirmed_at: user.confirmed_at
    }
  end
end
