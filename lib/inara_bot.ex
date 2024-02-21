defmodule InaraBot do
  @moduledoc """
  Documentation for `InaraBot`.
  """
  require Logger

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

  @opaque state() :: %__MODULE__{}

  defstruct [:forum, :last_seen_post]

  def new(forum) do
    %__MODULE__{
      forum: forum
    }
  end

  @doc """
  Replies with a correction. Or doesn't, I'm not the boss of it.

  ## Examples

      iex> InaraBot.respond_to("I like the Serenity very much")
      "It's just Serenity."

      iex> InaraBot.respond_to("I like the serenity very much")
      "It's just Serenity."

      iex> InaraBot.respond_to("I like the Serenity crew very much")
      nil
  """
  @spec respond_to(Post.t()) :: Post.t() | nil
  def respond_to(msg) do
    if String.match?(msg.body, @re) do
      %Post{
        body: "It's just Serenity.",
        parent: msg.id
      }
    end
  end

  @spec check_and_respond(state(), PostRepository.t()) :: state()
  def check_and_respond(state, repo) do
    new_posts = repo.fetch_latest(state.forum, state.last_seen_post)

    new_posts |> Enum.each(&Logger.debug("New Post: " <> inspect(&1)))

    new_posts
    |> Enum.map(&respond_to/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(&repo.send_post/1)

    last_seen_post =
      new_posts
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, state.last_seen_post)

    Logger.debug("Latest: #{(state.last_seen_post || "∅")} → #{last_seen_post}")
    %{state | last_seen_post: last_seen_post}
  end

end
