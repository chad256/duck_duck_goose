defmodule DuckDuckGoose.Peer do
  @moduledoc """
  Module for the peer server engaging in goose election.
  """

  use GenServer

  require Logger

  alias DuckDuckGoose.{RPC, RedisClient}

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def init(_arg) do
    Logger.info("Starting peer.")

    state = %{
      status: "duck",
      term: 0,
      election_timer: set_election_timer(),
      candidate: false,
      votes: 0,
      followers: []
    }

    {:ok, state}
  end

  def handle_call(:status, _, %{status: status} = state) do
    {:reply, status, state}
  end

  def handle_info(:start_election, %{status: status, term: old_term, election_timer: timer_ref}) do
    new_term = old_term + 1

    if RedisClient.node_list() |> length() == 1 do
      Process.cancel_timer(timer_ref)

      state = %{
        status: "goose",
        term: new_term,
        election_timer: set_election_timer(),
        candidate: false,
        votes: 0,
        followers: [self()]
      }

      {:noreply, state}
    else
      RPC.broadcast_election(new_term)

      state = %{
        status: "duck",
        term: new_term,
        election_timer: set_election_timer(),
        candidate: true,
        votes: 1,
        followers: []
      }

      {:noreply, state}
    end
  end

  def handle_info(
        {pid, {:vote_request, candidate_term}},
        %{term: term, election_timer: timer_ref} = peer_state
      ) do
    if candidate_term > term do
      Process.cancel_timer(timer_ref)
      RPC.send_vote(pid)

      state = %{
        status: "duck",
        term: candidate_term,
        election_timer: set_election_timer(),
        candidate: false,
        votes: 0,
        followers: []
      }

      {:noreply, state}
    else
      {:noreply, peer_state}
    end
  end

  def handle_info(
        :vote,
        %{term: term, election_timer: timer_ref, candidate: true, votes: votes} = peer_state
      ) do
    if votes + 1 >= quorum() do
      Process.cancel_timer(timer_ref)
      RPC.broadcast_leadership(term)

      state = %{
        status: "goose",
        term: term,
        election_timer: set_election_timer(),
        candidate: false,
        votes: 0,
        followers: [self()]
      }

      {:noreply, state}
    else
      {:noreply, %{peer_state | votes: votes + 1}}
    end
  end

  def handle_info(:vote, peer_state) do
    {:noreply, peer_state}
  end

  def handle_info(
        {pid, {:leader_heartbeat, leader_term}},
        %{term: term, election_timer: timer_ref} = peer_state
      ) do
    Logger.info("Leader heartbeat received.")

    if leader_term >= term do
      Process.cancel_timer(timer_ref)
      RPC.ack_leader_heartbeat(pid)

      state = %{
        status: "duck",
        term: leader_term,
        election_timer: set_election_timer(),
        candidate: false,
        votes: 0,
        followers: []
      }

      {:noreply, state}
    else
      {:noreply, peer_state}
    end
  end

  def handle_info(
        {pid, :follower_ack},
        %{status: "goose", term: term, election_timer: timer_ref, followers: followers} =
          peer_state
      ) do
    Logger.info("Follower ack received.")

    cond do
      pid in followers ->
        {:noreply, peer_state}

      length([pid | followers]) >= quorum() ->
        Process.cancel_timer(timer_ref)
        RPC.broadcast_leadership(term)
        {:noreply, %{peer_state | election_timer: set_election_timer(), followers: [self()]}}

      true ->
        {:noreply, %{peer_state | followers: [pid | followers]}}
    end
  end

  defp set_election_timer do
    Process.send_after(__MODULE__, :start_election, get_election_timeout())
  end

  defp get_election_timeout do
    Enum.random(150..300)
  end

  def quorum do
    RedisClient.node_list() |> length() |> div(2) |> Kernel.+(1)
  end
end
