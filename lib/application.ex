defmodule InaraBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type \\ nil, _args \\ []) do
    children = [
      # TODO: Have the bot server manage the repo lifecyle
      # TODO: Make the (Reddit) identity configurable here
      Infra.Reddit.Api,
      {InaraBot.Server, [repo: Infra.Reddit.Api]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InaraBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
