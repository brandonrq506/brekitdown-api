# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Brekitdown.Repo.insert!(%Brekitdown.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Brekitdown.{Accounts, Goals}
alias Brekitdown.Accounts.Scope

# Demo credentials (password must be >= 12 chars to pass the changeset).
email = "demo@example.com"
password = "demopassword123"

goals = [
  %{name: "Learn to use Claude", description: "Become more efficient and valuable at my job"},
  %{name: "Ship the goals feature", description: "Goals CRUD end to end, with tests and docs"},
  %{name: "Exercise 3x a week", description: "Build a sustainable fitness habit"}
]

case Accounts.get_user_by_email(email) do
  nil ->
    {:ok, user} = Accounts.register_user(%{email: email, password: password})
    scope = Scope.for_user(user)

    for attrs <- goals do
      {:ok, _goal} = Goals.create_goal(scope, attrs)
    end

    IO.puts("Seeded user #{email} (password: #{password}) with #{length(goals)} goals.")

  _user ->
    IO.puts("Seed user #{email} already exists — skipping.")
end
