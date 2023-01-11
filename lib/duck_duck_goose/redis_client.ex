defmodule DuckDuckGoose.RedisClient do
  @moduledoc """
  Redis client tracking the cluster configuration as new nodes are spun up or down.
  """

  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def node_list do
    GenServer.call(__MODULE__, :node_list)
  end

  def init(_) do
    {:ok, conn} = Redix.start_link()
    try_add_node(conn)
    {:ok, %{conn: conn}}
  end

  def handle_call(:node_list, _, %{conn: conn}) do
    node_list =
      conn
      |> fetch_node_list()
      |> parse_node_list()

    {:reply, node_list, %{conn: conn}}
  end

  def try_add_node(conn) do
    conn
    |> fetch_node_list()
    |> maybe_add_node(conn)
  end

  def fetch_node_list(conn) do
    Redix.command(conn, ["GET", "ddg_nodes"])
  end

  def parse_node_list({:ok, nil}), do: []
  def parse_node_list({:ok, ""}), do: []
  def parse_node_list({:ok, nodes_json}), do: Jason.decode!(nodes_json)

  def maybe_add_node({:ok, nil}, conn),
    do: Redix.command(conn, ["SET", "ddg_nodes", Jason.encode!([node()])])

  def maybe_add_node({:ok, ""}, conn),
    do: Redix.command(conn, ["SET", "ddg_nodes", Jason.encode!([node()])])

  def maybe_add_node({:ok, nodes_json}, conn) do
    nodes = Jason.decode!(nodes_json)

    if Atom.to_string(node()) not in nodes do
      nodes_json = Jason.encode!([node() | nodes])
      Redix.command(conn, ["SET", "ddg_nodes", nodes_json])
    end
  end
end
