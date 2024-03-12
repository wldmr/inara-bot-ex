defmodule Events do
  @moduledoc """
  A simple PubSub for Domain events.

  Subscribe to events via the specific `subscribe_*` functions (for some compile time safety),
  and emit them using the `emit_*` functions. Subscribing processes must then handle the
  corresponding event messages (see `event` typespec for the message formats)

  ## Examples

  Simple subscription (`subscribe_*()`) (`handle_call` takes a 2-tuple):

      iex> Events.init([])
      iex> defmodule MyEventsListenerA do
      ...>   use GenServer
      ...>
      ...>   @impl GenServer
      ...>   def init(_arg) do
      ...>     Events.subscribe_new_post
      ...>     {:ok, nil}
      ...>   end
      ...>
      ...>   @impl GenServer
      ...>   def handle_info({:new_post, %Post{} = post}, _previous_message),
      ...>     do: {:noreply, post.body}
      ...>
      ...>   @impl GenServer
      ...>   def handle_call(:latest_message, _from, msg),
      ...>    do: {:reply, msg, msg}
      ...> end
      iex> {:ok, pid} = GenServer.start_link(MyEventsListenerA, [])
      iex> Events.emit_new_post(%Post{body: "See?"})
      iex> GenServer.call(pid, :latest_message)
      "See?"

  With associated data (`subscribe_*(some_data)`). Note that `handle_call` takes a 3-tuple;
  the third element is `some_data` given to the `subscribe_*()` function:

      iex> Events.init([])
      iex> defmodule MyEventsListenerB do
      ...>   use GenServer
      ...>
      ...>   @impl GenServer
      ...>   def init(_arg) do
      ...>     Events.subscribe_new_post(:me)  # <- Associating data with current registration
      ...>     {:ok, nil}
      ...>   end
      ...>
      ...>   @impl GenServer
      ...>   def handle_info({:new_post, %Post{}, data}, _),
      ...>     do: {:noreply, data}
      ...>
      ...>   @impl GenServer
      ...>   def handle_call(:latest_message, _from, msg),
      ...>     do: {:reply, msg, msg}
      ...> end
      iex> {:ok, pid} = GenServer.start_link(MyEventsListenerB, [])
      iex> Events.emit_new_post(%Post{})
      iex> GenServer.call(pid, :latest_message)
      :me
  """
  use Supervisor
  require Logger

  @events_registry String.to_atom("#{__MODULE__}.Events")

  @type assoc_data :: any()

  @type event ::
          {:new_post, Post.t()}
          | {:new_reply, Post.t()}

  @type registration :: {:ok, pid()} | {:error, {:already_registered, pid()}}

  def start_link(init_arg),
    do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl Supervisor
  def init(_init_arg) do
    children = [
      {Registry, keys: :duplicate, name: @events_registry}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec subscribe(atom(), assoc_data()) :: {:ok, pid()} | {:error, {:already_registered, pid()}}
  defp subscribe(event_name, data) do
    procname = self() |> Process.info() |> Keyword.get(:registered_name, inspect(self()))
    Logger.debug("Registering #{procname} for #{event_name} with data #{data}.")
    Registry.register(@events_registry, event_name, data)
  end

  @spec emit(Events.event()) :: :ok
  defp emit({event_name, payload}) do
    Registry.dispatch(@events_registry, event_name, fn entries ->
      for {pid, maybe_data} <- entries do
        case maybe_data do
          nil -> send(pid, {event_name, payload})
          data -> send(pid, {event_name, payload, data})
        end
      end
    end)
  end

  @spec subscribe_new_post(assoc_data() | nil) :: registration()
  def subscribe_new_post(data \\ nil), do: subscribe(:new_post, data)

  @spec emit_new_post(Post.t()) :: :ok
  def emit_new_post(%Post{} = post), do: emit({:new_post, post})

  @spec subscribe_new_reply(assoc_data() | nil) :: registration()
  def subscribe_new_reply(data \\ nil), do: subscribe(:new_reply, data)

  @spec emit_new_reply(Post.t()) :: :ok
  def emit_new_reply(%Post{} = reply), do: emit({:new_reply, reply})
end
