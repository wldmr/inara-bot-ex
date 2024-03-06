defmodule InaraBot do
  @moduledoc """
  Documentation for `InaraBot`.
  """
  require Logger

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

  @forum "firefly"

  @opaque t() :: String.t() | nil

  def new() do
    nil
  end

  @doc """
  Replies with a correction. Or doesn't, I'm not the boss of it.

  ## Examples

      iex> InaraBot.respond_to(%Post{body: "I like the Serenity very much"})
      %Post{body: "> the Serenity\\n\\nIt's just Serenity."}

      iex> InaraBot.respond_to(%Post{body: "I like the serenity very much"})
      %Post{body: "> the serenity\\n\\nIt's just Serenity."}

      iex> InaraBot.respond_to(%Post{body: "I like the Serenity crew very much"})
      nil
  """
  @spec respond_to(Post.t()) :: Post.t() | nil
  def respond_to(msg) do
    case Regex.run(@re, msg.body) do
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
    new_posts = Reddit.fetch_latest(identity, @forum, last_seen_post)

    Enum.each(new_posts, &Logger.debug("New Post: " <> inspect(&1)))

    new_posts
    |> Enum.map(&respond_to/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn post -> Reddit.send_post(identity, post) end)

    new_last_seen_post =
      new_posts
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, last_seen_post)

    Logger.debug("Latest: #{last_seen_post || "∅"} → #{new_last_seen_post}")
    new_last_seen_post
  end
end
