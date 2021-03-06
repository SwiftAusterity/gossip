defmodule Web.UserGameController do
  use Web, :controller

  plug Web.Plugs.VerifyUser

  alias Gossip.Games

  def index(conn, _params) do
    conn
    |> assign(:changeset, Games.new())
    |> render("index.html")
  end

  def create(conn, %{"game" => params}) do
    %{current_user: user} = conn.assigns

    case Games.register(user, params) do
      {:ok, _game} ->
        conn
        |> put_flash(:info, "Game created!")
        |> redirect(to: user_game_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "There was an issue creating the game.")
        |> redirect(to: user_game_path(conn, :index))
    end
  end
end
