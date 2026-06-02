defmodule BrekitdownWeb.Router do
  use BrekitdownWeb, :router

  import BrekitdownWeb.UserAuth

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_current_scope_for_user
  end

  pipeline :authenticated_api do
    plug :require_authenticated_user
  end

  scope "/api", BrekitdownWeb do
    pipe_through :api

    post "/users/register", UserRegistrationController, :create
    post "/users/log-in", UserSessionController, :create

    scope "/" do
      pipe_through :authenticated_api

      get "/users/me", UserController, :me
      delete "/users/log-out", UserSessionController, :delete
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:brekitdown, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: BrekitdownWeb.Telemetry
    end
  end
end
