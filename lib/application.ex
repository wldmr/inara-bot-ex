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
      Site.Reddit.Auth,
      InaraBot,
      Post.Poster,
      # Order is important here: We start the watcher last so that the consumers don't miss anything.
      # Feels somewhat brittle, but it'll do in his simple case.
      {Post.Watcher, forum: "wldmr_bot_practice"}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InaraBot.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
