defmodule BrekitdownWeb.TimeEntryJSON do
  alias Brekitdown.TimeEntries.TimeEntry

  @doc "Renders a list of time entries."
  def index(%{time_entries: time_entries}) do
    %{data: for(time_entry <- time_entries, do: data(time_entry))}
  end

  @doc "Renders a single time entry."
  def show(%{time_entry: time_entry}) do
    %{data: data(time_entry)}
  end

  defp data(%TimeEntry{} = time_entry) do
    %{
      reference_xid: time_entry.reference_xid,
      started_at: time_entry.started_at,
      ended_at: time_entry.ended_at
    }
  end
end
