defmodule Gossip.Application do
  @moduledoc false

  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Gossip.Repo, []),
      supervisor(Web.Endpoint, []),
      {Gossip.Presence, []},
      {Metrics.Server, []},
    ]

    Metrics.Setup.setup()

    opts = [strategy: :one_for_one, name: Gossip.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
