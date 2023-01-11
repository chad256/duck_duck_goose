defmodule DuckDuckGoose.RPC do
  @moduledoc """
  Defines functions for sending messages to other peers in the cluster.
  """

  alias DuckDuckGoose.{Peer, RedisClient}

  require Logger

  def broadcast_election(term) do
    Logger.info("Sending election notice.")

    RedisClient.node_list()
    |> remove_self()
    |> Enum.map(&Process.send({Peer, String.to_atom(&1)}, {self(), {:vote_request, term}}, []))
  end

  def broadcast_leadership(term) do
    Logger.info("Sending leader heartbeat.")

    RedisClient.node_list()
    |> remove_self()
    |> Enum.map(
      &Process.send({Peer, String.to_atom(&1)}, {self(), {:leader_heartbeat, term}}, [])
    )
  end

  def ack_leader_heartbeat(pid) do
    Logger.info("Sending follower ack.")
    Process.send(pid, {self(), :follower_ack}, [])
  end

  def send_vote(pid) do
    Logger.info("Sending Vote.")
    Process.send(pid, :vote, [])
  end

  def remove_self(nodes) do
    List.delete(nodes, Atom.to_string(node()))
  end
end
