defmodule InaraBot do
  require Logger

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

  @doc """
  Replies with a correction. Or doesn't, I'm not the boss of it.

  ## Examples

      iex> InaraBot.respond_to(%Post{body: "I like the Serenity."})
      %Post{body: "> the Serenity\\n\\nIt's just Serenity."}

      iex> InaraBot.respond_to(%Post{body: "I like the serenity very much"})
      %Post{body: "> the serenity\\n\\nIt's just Serenity."}

  Only the first occurrence is admonished:

      iex> InaraBot.respond_to(%Post{body: "I like the serenity very much"})
      %Post{body: "> the serenity\\n\\nIt's just Serenity."}

  including the heading, if present:

      iex> InaraBot.respond_to(%Post{heading: "The Serenity is cool", body: "I like the serenity very much"})
      %Post{body: "> The Serenity\\n\\nIt's just Serenity."}

  There are exceptions where the construction uses "serenity" as an adjective:

      iex> InaraBot.respond_to(%Post{body: "I like the Serenity crew very much"})
      nil

  """
  @spec respond_to(Post.t()) :: Post.t() | nil
  def respond_to(msg) do
    text = "#{msg.heading || ""}\n\n#{msg.body || ""}"

    case Regex.run(@re, text) do
      [offender] ->
        %Post{
          body: "> #{offender}\n\nIt's just Serenity.",
          parent: msg.id
        }

      nil ->
        nil
    end
  end

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
