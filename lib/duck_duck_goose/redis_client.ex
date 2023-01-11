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

  def remove_node do
    GenServer.call(__MODULE__, :remove_node)
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

  def handle_call(:remove_node, _, %{conn: conn}) do
    resp =
      conn
      |> fetch_node_list()
      |> parse_node_list()
      |> do_remove_node(conn)

    {:reply, resp, %{conn: conn}}
  end

  defp try_add_node(conn) do
    conn
    |> fetch_node_list()
    |> maybe_add_node(conn)
  end

  defp fetch_node_list(conn) do
    Redix.command(conn, ["GET", "ddg_nodes"])
  end

  defp update_node_list(nodes, conn) do
    nodes_json = Jason.encode!(nodes)
    Redix.command(conn, ["SET", "ddg_nodes", nodes_json])
  end

  defp parse_node_list({:ok, nil}), do: []
  defp parse_node_list({:ok, ""}), do: []
  defp parse_node_list({:ok, nodes_json}), do: Jason.decode!(nodes_json)

  defp maybe_add_node({:ok, nil}, conn), do: update_node_list([node()], conn)
  defp maybe_add_node({:ok, ""}, conn), do: update_node_list([node()], conn)

  defp maybe_add_node({:ok, nodes_json}, conn) do
    nodes = Jason.decode!(nodes_json)

    if Atom.to_string(node()) not in nodes do
      update_node_list([node() | nodes], conn)
    end
  end

  defp do_remove_node([], _), do: []

  defp do_remove_node(node_list, conn) do
    node_list
    |> List.delete(Atom.to_string(node()))
    |> update_node_list(conn)
  end
end
