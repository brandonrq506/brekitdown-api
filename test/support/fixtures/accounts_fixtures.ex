defmodule Brekitdown.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.Accounts` context.
  """

  alias Brekitdown.Accounts
  alias Brekitdown.Accounts.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  @doc """
  Registers a confirmation-less, password-backed user (the only registration
  path the API exposes).
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end
end
