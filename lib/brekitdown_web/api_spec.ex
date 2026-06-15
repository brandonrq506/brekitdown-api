defmodule BrekitdownWeb.ApiSpec do
  @moduledoc "Assembles the OpenAPI 3 document from the router and schema modules."

  alias BrekitdownWeb.{Endpoint, Router}
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, SecurityScheme, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Brekitdown API",
        version: Application.spec(:brekitdown, :vsn) |> to_string()
      },
      servers: [Server.from_endpoint(Endpoint)],
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{"bearer" => %SecurityScheme{type: "http", scheme: "bearer"}}
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
