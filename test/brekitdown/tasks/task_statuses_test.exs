defmodule Brekitdown.Tasks.TaskStatusesTest do
  use ExUnit.Case, async: true

  import Brekitdown.Tasks.TaskStatuses

  alias Brekitdown.Tasks.TaskStatuses

  describe "open/0" do
    test "returns the Open task statuses" do
      assert Enum.sort(TaskStatuses.open()) == Enum.sort([:scheduled, :in_progress, :on_hold])
    end
  end

  describe "closed/0" do
    test "returns the Closed task statuses" do
      assert Enum.sort(TaskStatuses.closed()) == Enum.sort([:completed, :dropped])
    end
  end

  test "open and closed cover every status exactly once" do
    assert Enum.sort(TaskStatuses.open() ++ TaskStatuses.closed()) ==
             Enum.sort(TaskStatuses.all())
  end

  describe "is_open_status/1" do
    test "true for every open status, false for every closed one" do
      for status <- TaskStatuses.open(), do: assert(open_guard?(status))
      for status <- TaskStatuses.closed(), do: refute(open_guard?(status))
    end

    test "false for non-statuses" do
      refute open_guard?(:bogus)
      refute open_guard?(nil)
    end
  end

  describe "is_closed_status/1" do
    test "true for every closed status, false for every open one" do
      for status <- TaskStatuses.closed(), do: assert(closed_guard?(status))
      for status <- TaskStatuses.open(), do: refute(closed_guard?(status))
    end

    test "false for non-statuses" do
      refute closed_guard?(:bogus)
      refute closed_guard?(nil)
    end
  end

  defp open_guard?(status) when is_open_status(status), do: true
  defp open_guard?(_), do: false

  defp closed_guard?(status) when is_closed_status(status), do: true
  defp closed_guard?(_), do: false
end
