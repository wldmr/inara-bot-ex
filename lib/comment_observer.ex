defmodule CommentObserver do
  require Logger
  use GenServer

  @singleton_process __MODULE__

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, nil, name: @singleton_process)
  end

  @impl GenServer
  @spec init(nil) :: {:ok, nil, {:continue, :check}}
  def init(init_arg \\ nil) do
    {:ok, init_arg, {:continue, :check}}
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
    Process.send_after(self(), :check, 10_000)

    Logger.info("Checking for new comments.")

    {new_comments, new_state} = RedditApi.latest_comments(state)

    Logger.info("#{Enum.count(new_comments)} new comments")

    Enum.each(
      new_comments,
      &IO.puts(
        "#{DateTime.from_unix!(trunc(&1["created"]))} – #{&1["id"]} – #{&1["author"]}:\n#{&1["body"]}\n"
      )
    )

    new_state
  end
end
