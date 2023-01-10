import Config

config :duck_duck_goose, http_port: System.fetch_env!("DDG_HTTP_PORT")
