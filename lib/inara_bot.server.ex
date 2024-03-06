defmodule InaraBot.Server do
  require Logger
  use GenServer

  @opaque t() :: %__MODULE__{identity: atom(), bot: InaraBot.t()}

  @enforce_keys [:identity, :bot]
  defstruct [:identity, :bot]

  def child_spec(identity) do
    init = %__MODULE__{
      identity: identity,
      bot: InaraBot.new()
    }

    %{
      id: "inarabot-reddit-#{identity}",
      start: {__MODULE__, :start_link, [init]}
    }
  end

  @spec start_link(t()) :: GenServer.on_start()
  def start_link(%__MODULE__{} = init) do
    name = String.to_atom("inarabot-reddit-#{init.identity}")
    GenServer.start_link(__MODULE__, init, name: name)
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
    Logger.info("Checking for new comments for #{state.identity}")
    new_botstate = InaraBot.check_and_respond(state.identity, state.bot)
    Process.send_after(self(), :check, 10_000)
    %{state | bot: new_botstate}
  end
end
