defmodule DuckDuckGoose.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome to Duck Duck Goose.")
  end

  match _ do
    send_resp(conn, 404, "Page Not Found.")
  end

  def port do
    Application.fetch_env!(:duck_duck_goose, :http_port)
    |> String.to_integer()
  end
end
