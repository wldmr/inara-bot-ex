defmodule Post.Poster do
  require Logger

  use GenServer

  def child_spec(opts \\ []) do
    identity = Keyword.get(opts, :identity, :default)

    %{
      id: "#{__MODULE__}.#{identity}",
      start: {__MODULE__, :start_link, [identity]}
    }
  end

  @spec start_link(atom()) :: GenServer.on_start()
  def start_link(identity) do
    name = "#{__MODULE__}.#{identity}"
    GenServer.start_link(__MODULE__, identity, name: String.to_atom(name))
  end

  @impl GenServer
  def init(identity) do
    Events.subscribe_new_reply(identity)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info({:new_reply, %Post{} = post, identity}, state) do
    Reddit.send_post(identity, post)
    {:noreply, state}
  end
end
