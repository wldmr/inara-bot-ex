defmodule CommentObserver do
  use GenServer

  @singleton_process __MODULE__

  @type t() :: MapSet.t(String.t())

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: @singleton_process)
  end

  @impl GenServer
  @spec init(Enumerable.t(String.t())) :: {:ok, t(), {:continue, :check}}
  def init(init_arg \\ MapSet.new()) do
    init_state =
      case init_arg do
        %MapSet{} = already_seen -> already_seen
        already_seen -> MapSet.new(already_seen)
      end

    {:ok, init_state, {:continue, :check}}
  end

  @impl GenServer
  @spec handle_continue(:check, t()) :: {:noreply, t()}
  def handle_continue(:check, already_seen) do
    check_repeatedly(already_seen)
  end

  @impl GenServer
  @spec handle_info(:check, t()) :: {:noreply, t()}
  def handle_info(:check, already_seen) do
    check_repeatedly(already_seen)
  end

  @spec check_repeatedly(t()) :: {:noreply, t()}
  defp check_repeatedly(already_seen) do
    Process.send_after(self(), :check, 10_000)

    IO.puts("Checking for new comments")

    new_comments =
      RedditApi.latest_comments()
      |> Enum.filter(&(!MapSet.member?(already_seen, &1)))

    IO.puts("#{Enum.count(new_comments)} new comments")

    new_comments
    |> Enum.each(fn comment -> IO.puts("#{comment["author"]} said '#{comment["body"]}'") end)

    already_seen = new_comments |> Enum.reduce(already_seen, &MapSet.put(&2, &1))

    {:noreply, already_seen}
  end
end
