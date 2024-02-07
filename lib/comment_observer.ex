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

  defp check_repeatedly(previous_latest) do
    Process.send_after(self(), :check, 10_000)

    Logger.info("Checking for new comments.")

    new_comments = Reddit.Api.fetch_latest(previous_latest)

    Logger.info("#{Enum.count(new_comments)} new comments")

    Enum.each(new_comments, &IO.puts(pretty(&1)))

    new_latest = Enum.at(new_comments, 0, previous_latest)
    Logger.debug("Latest: #{(previous_latest || %{}) |> Map.get(:id)} → #{new_latest.id}")
    new_latest
  end

  defp pretty(%Post{} = post) do
    "#{post.timestamp} – #{post.id} – #{post.username}:\n#{post.body}\n"
  end
end
