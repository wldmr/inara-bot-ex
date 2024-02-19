defmodule InaraBot.Server do
  require Logger
  use GenServer

  @singleton_process __MODULE__

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: @singleton_process)
  end

  @impl GenServer
  @spec init(nil) :: {:ok, InaraBot.state(), {:continue, :check}}
  def init(_init_arg \\ nil) do
    {:ok, InaraBot.new(%Forum{name: "firefly"}), {:continue, :check}}
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
    # TODO: This is obviously still wrong; need to create a way to get the repository dynamically
    repo = Process.whereis(Reddit.Api) |> IO.inspect() |> Process.get() |> IO.inspect()
    Logger.info("Checking for new comments in #{repo}")
    new_state = InaraBot.check_and_respond(state, Reddit.Api)
    Process.send_after(self(), :check, 10_000)
    new_state
  end
end
