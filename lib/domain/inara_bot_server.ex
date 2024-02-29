defmodule InaraBot.Server do
  require Logger
  use GenServer

  @opaque t() :: %__MODULE__{repo: PostRepository.SpecficRepo.t(), bot: InaraBot.t()}

  @enforce_keys [:repo, :bot]
  defstruct [:repo, :bot]

  def child_spec(repo) do
    init = %__MODULE__{
      repo: repo,
      bot: InaraBot.new(%Domain.Forum{name: "firefly"})
    }

    %{
      id: "InaraBot-#{repo}",
      start: {__MODULE__, :start_link, [init]}
    }
  end

  @spec start_link(t()) :: GenServer.on_start()
  def start_link(%__MODULE__{} = init) do
    GenServer.start_link(__MODULE__, init)
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
    Logger.info("Checking for new comments for #{state.repo}")
    new_botstate = InaraBot.check_and_respond(state.bot, state.repo)
    Process.send_after(self(), :check, 10_000)
    %{state | bot: new_botstate}
  end
end
