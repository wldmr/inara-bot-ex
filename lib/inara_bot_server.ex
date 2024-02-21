defmodule InaraBot.Server do
  require Logger
  use GenServer

  @opaque t() :: %__MODULE__{}
  defstruct [:repo, :botstate]

  def child_spec(repo: repo) do
    init_botstate = %__MODULE__{
      repo: repo,
      botstate: InaraBot.new(%Forum{name: "firefly"})
    }

    %{
      id: "InaraBot-for-#{inspect(repo)}",
      start: {__MODULE__, :start_link, [init_botstate]}
    }
  end

  @spec start_link(t()) :: GenServer.on_start()
  def start_link(init_state) do
    GenServer.start_link(__MODULE__, init_state)
  end

  @impl GenServer
  @spec init(module()) :: {:ok, t(), {:continue, :check}}
  def init(%__MODULE__{} = init_state) do
    {:ok, init_state, {:continue, :check}}
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
    Logger.info("Checking for new comments in #{state.repo}")
    new_botstate = InaraBot.check_and_respond(state.botstate, state.repo)
    Process.send_after(self(), :check, 10_000)
    %{state | botstate: new_botstate}
  end
end
