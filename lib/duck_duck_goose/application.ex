defmodule DuckDuckGoose.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: DuckDuckGoose.Worker.start_link(arg)
      # {DuckDuckGoose.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: DuckDuckGoose.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
