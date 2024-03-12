defmodule InaraBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type \\ nil, _args \\ []) do
    children = [
      Events,
      Reddit.Auth,
      InaraBot.Server,
      Post.Poster,
      Post.Watcher,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InaraBot.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
