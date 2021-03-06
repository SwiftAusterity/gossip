defmodule Gossip.Presence do
  @moduledoc """
  Track online presence of games
  """

  use GenServer

  alias Gossip.Presence.Client
  alias Gossip.Presence.Server

  @ets_key :gossip_presence

  @type supports :: [String.t()]
  @type players :: [String.t()]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Update a game and their players presence
  """
  @spec update_game(Game.t(), supports(), players()) :: :ok
  def update_game(game, supports, players) do
    GenServer.call(__MODULE__, {:update, game, supports, players})
  end

  @spec update_game(Socket.state()) :: :ok
  def update_game(state) do
    GenServer.call(__MODULE__, {:update, state.game, state.supports, state.players})
  end

  # for tests
  @doc false
  def reset() do
    GenServer.call(__MODULE__, {:reset})
  end

  @doc """
  Get a list of online games
  """
  @spec online_games() :: [{Game.t(), players()}]
  def online_games(), do: Client.online_games()

  @doc false
  def ets_key(), do: @ets_key

  def init(_) do
    create_table()

    {:ok, %{}}
  end

  def handle_call({:update, game, supports, players}, _from, state) do
    {:ok, state} = Server.update_game(state, game, supports, players)
    {:reply, :ok, state}
  end

  def handle_call({:reset}, _from, state) do
    :ets.delete(ets_key())
    create_table()
    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(@ets_key, [:set, :protected, :named_table])
  end
end
