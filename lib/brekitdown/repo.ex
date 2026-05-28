defmodule Brekitdown.Repo do
  use Ecto.Repo,
    otp_app: :brekitdown,
    adapter: Ecto.Adapters.Postgres
end
