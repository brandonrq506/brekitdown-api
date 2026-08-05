defmodule BrekitdownWeb.ErrorJSONTest do
  use BrekitdownWeb.ConnCase, async: true

  test "renders 404" do
    assert BrekitdownWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert BrekitdownWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end

  test "renders 409 with both the code and the detail" do
    assert BrekitdownWeb.ErrorJSON.render("409.json", %{
             code: "entry_already_running",
             detail: "This task already has a time entry that has not ended."
           }) ==
             %{
               errors: %{
                 code: "entry_already_running",
                 detail: "This task already has a time entry that has not ended."
               }
             }
  end

  test "falls back to the status message when a 409 carries no code" do
    assert BrekitdownWeb.ErrorJSON.render("409.json", %{}) == %{errors: %{detail: "Conflict"}}
  end
end
