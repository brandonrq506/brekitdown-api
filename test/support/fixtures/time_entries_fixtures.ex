defmodule Brekitdown.TimeEntriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Brekitdown.TimeEntries` context.
  """

  @doc """
  Generate a time entry.

  Defaults to a finished entry that started two hours ago and ran for one hour.
  Pass `ended_at: nil` to get an open (running) one.
  """
  def time_entry_fixture(scope, task, attrs \\ %{}) do
    started_at = DateTime.utc_now(:second) |> DateTime.shift(hour: -2)

    attrs =
      Enum.into(attrs, %{
        started_at: started_at,
        ended_at: DateTime.shift(started_at, hour: 1)
      })

    {:ok, time_entry} = Brekitdown.TimeEntries.create_time_entry(scope, task, attrs)
    time_entry
  end
end
