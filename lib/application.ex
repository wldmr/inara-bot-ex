defmodule InaraBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type \\ nil, _args \\ []) do
    children = [
      {Registry, [keys: :unique, name: InaraBot.Application.Registry]},
      # TODO: Have the bot server supervise its own Repository. Maybe?
      {PostRepository.Reddit, :wldmr_reddit},
      {InaraBot.Server, PostRepository.Handle.new(PostRepository.Reddit, :wldmr_reddit)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InaraBot.Application.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec via_identity(module(), PostRepository.identity()) :: {:via, module(), term()}
  def via_identity(module, identity) do
    {:via, Registry, {InaraBot.Application.Registry, {module, identity}}}
  end
end
