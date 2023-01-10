defmodule DuckDuckGoose.Application do
  @moduledoc false

  use Application

  alias DuckDuckGoose.Router

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Router, options: [port: Router.port()]}
    ]

    opts = [strategy: :one_for_one, name: DuckDuckGoose.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
