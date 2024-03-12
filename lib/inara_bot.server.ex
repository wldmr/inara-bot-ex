defmodule InaraBot.Server do
  require Logger
  use GenServer

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl GenServer
  @spec init(any()) :: {:ok, []}
  def init(_init_arg) do
    Events.subscribe_new_post
    {:ok, []}
  end

  @impl GenServer
  def handle_info({:new_post, %Post{} = post}, state) do
    case InaraBot.respond_to(post) do
      %Post{} = reply -> Events.emit_new_post(reply)
      nil -> nil
    end

    {:noreply, state}
  end
end
