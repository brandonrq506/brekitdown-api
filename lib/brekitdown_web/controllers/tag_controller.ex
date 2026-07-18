defmodule BrekitdownWeb.TagController do
  use BrekitdownWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Brekitdown.Tags
  alias Brekitdown.Tags.Tag

  alias BrekitdownWeb.Schemas.{
    ChangesetError,
    Error,
    TagCreateRequest,
    TagResponse,
    TagsResponse,
    TagUpdateRequest
  }

  action_fallback BrekitdownWeb.FallbackController
  plug OpenApiSpex.Plug.CastAndValidate, render_error: BrekitdownWeb.ValidationErrorPlug

  tags(["tags"])

  operation(:index,
    summary: "List the current user's tags",
    security: [%{"bearer" => []}],
    responses: [
      ok: {"The user's tags", "application/json", TagsResponse},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def index(conn, _params) do
    tags = Tags.list_tags(conn.assigns.current_scope)
    render(conn, :index, tags: tags)
  end

  operation(:create,
    summary: "Create a tag",
    security: [%{"bearer" => []}],
    request_body: {"Tag attributes", "application/json", TagCreateRequest},
    responses: [
      created: {"Tag created", "application/json", TagResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def create(conn, _params) do
    %TagCreateRequest{tag: tag_params} = OpenApiSpex.body_params(conn)

    with {:ok, %Tag{} = tag} <- Tags.create_tag(conn.assigns.current_scope, tag_params) do
      conn
      |> put_status(:created)
      |> render(:show, tag: tag)
    end
  end

  operation(:show,
    summary: "Get a tag by reference_xid",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The tag's reference_xid"]
    ],
    responses: [
      ok: {"The tag", "application/json", TagResponse},
      not_found: {"Tag not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def show(conn, %{id: id}) do
    tag = Tags.get_tag!(conn.assigns.current_scope, id)
    render(conn, :show, tag: tag)
  end

  operation(:update,
    summary: "Update a tag",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The tag's reference_xid"]
    ],
    request_body: {"Tag attributes", "application/json", TagUpdateRequest},
    responses: [
      ok: {"Tag updated", "application/json", TagResponse},
      unprocessable_entity: {"Validation errors", "application/json", ChangesetError},
      not_found: {"Tag not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def update(conn, %{id: id}) do
    %TagUpdateRequest{tag: tag_params} = OpenApiSpex.body_params(conn)

    tag = Tags.get_tag!(conn.assigns.current_scope, id)

    with {:ok, %Tag{} = tag} <- Tags.update_tag(conn.assigns.current_scope, tag, tag_params) do
      render(conn, :show, tag: tag)
    end
  end

  operation(:delete,
    summary: "Delete a tag",
    security: [%{"bearer" => []}],
    parameters: [
      id: [in: :path, type: :string, required: true, description: "The tag's reference_xid"]
    ],
    responses: [
      no_content: "Tag deleted",
      not_found: {"Tag not found", "application/json", Error},
      unauthorized: {"Unauthorized", "application/json", Error}
    ]
  )

  def delete(conn, %{id: id}) do
    tag = Tags.get_tag!(conn.assigns.current_scope, id)

    with {:ok, %Tag{}} <- Tags.delete_tag(conn.assigns.current_scope, tag) do
      send_resp(conn, :no_content, "")
    end
  end
end
