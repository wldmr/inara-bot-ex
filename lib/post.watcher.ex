defmodule Post.Watcher do
  require Logger

  use GenServer

  @type t() :: %__MODULE__{identity: atom(), forum: String.t(), latest: Reddit.latest_token()}

  @enforce_keys [:identity, :forum]
  defstruct identity: :default,
            forum: "firefly",
            latest: nil

  def child_spec(opts \\ []) do
    state = struct(__MODULE__, opts)

    %{
      id: "#{__MODULE__}.#{state.identity}.#{state.forum}",
      start: {__MODULE__, :start_link, [state]}
    }
  end

  @spec start_link(t()) :: GenServer.on_start()
  def start_link(%__MODULE__{} = init) do
    name = "#{__MODULE__}.#{init.identity}.#{init.forum}"
    GenServer.start_link(__MODULE__, init, name: String.to_atom(name))
  end

  @impl GenServer
  @spec init(t()) :: {:ok, t(), {:continue, :check}}
  def init(%__MODULE__{} = init) do
    {:ok, init, {:continue, :check}}
  end

  @impl GenServer
  def handle_continue(:check, state) do
    new_state = check_repeatedly(state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(:check, state) do
    new_state = check_repeatedly(state)
    {:noreply, new_state}
  end

  defp check_repeatedly(state) do
    Logger.info("Checking for new comments in #{state.forum} as #{Identity.username!(state.identity)}")
    {posts, latest} = Reddit.fetch_latest(state.identity, state.forum, state.latest)

    username = Identity.username!(state.identity)

    posts
    |> Enum.filter(&(&1.username != username))
    |> Enum.each(&Events.emit_new_post/1)

    Process.send_after(self(), :check, 10_000)
    %{state | latest: latest}
  end
end
