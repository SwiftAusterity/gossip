defmodule Gossip.Games do
  @moduledoc """
  Context for games
  """

  alias Gossip.Games.Game
  alias Gossip.Repo

  @type id :: integer()
  @type game_params :: map()
  @type token :: String.t()

  @doc """
  Start a new game
  """
  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Game{} |> Game.changeset(%{})

  @doc """
  Start to a edit game
  """
  @spec edit(Game.t()) :: Ecto.Changeset.t()
  def edit(game), do: game |> Game.changeset(%{})

  @doc """
  Fetch a game
  """
  @spec get(id()) :: Game.t()
  def get(game_id) do
    case Repo.get(Game, game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, game}
    end
  end

  @doc """
  Fetch a game based on the user
  """
  @spec get(User.t(), id()) :: Game.t()
  def get(user, game_id) do
    case Repo.get_by(Game, user_id: user.id, id: game_id) do
      nil ->
        {:error, :not_found}

      game ->
        {:ok, game}
    end
  end

  @doc """
  Register a new game
  """
  @spec register(User.t(), game_params()) :: {:ok, Game.t()}
  def register(user, params) do
    user
    |> Ecto.build_assoc(:games)
    |> Game.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update a game
  """
  @spec update(Game.t(), game_params()) :: {:ok, Game.t()}
  def update(game, params) do
    game
    |> Game.changeset(params)
    |> Repo.update()
  end

  @doc """
  Update a game
  """
  @spec regenerate_client_tokens(User.t(), id()) :: {:ok, Game.t()}
  def regenerate_client_tokens(user, id) do
    case Repo.get_by(Game, user_id: user.id, id: id) do
      nil ->
        {:error, :not_found}

      game ->
        game
        |> Game.regenerate_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Validate a socket
  """
  @spec validate_socket(String.t(), String.t()) :: {:ok, Game.t()} | {:error, :invalid}
  def validate_socket(client_id, client_secret, user_agent_params \\ %{}) do
    with {:ok, client_id} <- Ecto.UUID.cast(client_id),
         {:ok, client_secret} <- Ecto.UUID.cast(client_secret),
         {:ok, game} <- get_game(client_id),
         {:ok, game} <- validate_secret(game, client_secret) do
      record_user_agent(game, user_agent_params)
    else
      _ ->
        {:error, :invalid}
    end
  end

  defp get_game(client_id) do
    case Repo.get_by(Game, client_id: client_id) do
      nil ->
        {:error, :invalid}

      game ->
        {:ok, game}
    end
  end

  defp validate_secret(game, client_secret) do
    case game.client_secret == client_secret do
      true ->
        {:ok, game}

      false ->
        {:error, :invalid}
    end
  end

  defp record_user_agent(game, user_agent_params) do
    changeset = game |> Game.user_agent_changeset(user_agent_params)

    case changeset |> Repo.update() do
      {:ok, game} ->
        {:ok, game}

      {:error, _} ->
        {:error, :invalid}
    end
  end
end
