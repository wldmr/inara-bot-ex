defmodule InaraBot do
  @moduledoc """
  Documentation for `InaraBot`.
  """
  require Logger

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

  # @forum "firefly"
  @forum "wldmr_bot_practice"

  @opaque t() :: String.t() | nil

  def new() do
    nil
  end

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

  @spec check_and_respond(atom(), String.t()) :: t()
  def check_and_respond(identity, last_seen_post) do
    {new_posts, token} = Reddit.fetch_latest(identity, @forum, last_seen_post)

    Enum.each(new_posts, &Logger.debug("New Post: " <> inspect(&1)))

    new_posts
    |> Enum.map(&respond_to/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn post -> Reddit.send_post(identity, post) end)

    Logger.debug("Latest: #{inspect(last_seen_post)} → #{inspect(token)}")
    token
  end
end
