defmodule InaraBot do
  @moduledoc """
  Documentation for `InaraBot`.
  """
  require Logger

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

  @opaque t() :: %__MODULE__{}

  defstruct [:forum, :last_seen_post]

  def new(forum) do
    %__MODULE__{
      forum: forum
    }
  end

  @doc """
  Replies with a correction. Or doesn't, I'm not the boss of it.

  ## Examples

      iex> InaraBot.respond_to(%Domain.Post{body: "I like the Serenity very much"})
      %Domain.Post{body: "> the Serenity\\n\\nIt's just Serenity."}

      iex> InaraBot.respond_to(%Domain.Post{body: "I like the serenity very much"})
      %Domain.Post{body: "> the serenity\\n\\nIt's just Serenity."}

      iex> InaraBot.respond_to(%Domain.Post{body: "I like the Serenity crew very much"})
      nil
  """
  @spec respond_to(Domain.Post.t()) :: Post.t() | nil
  def respond_to(msg) do
    case Regex.run(@re, msg.body) do
      [offender] ->
        %Domain.Post{
          body: "> #{offender}\n\nIt's just Serenity.",
          parent: msg.id
        }

      nil ->
        nil
    end
  end

  @spec check_and_respond(t(), PostRepository.t()) :: t()
  def check_and_respond(state, repo) do
    new_posts = PostRepository.fetch_latest(repo, state.forum, state.last_seen_post)

    Enum.each(new_posts, &Logger.debug("New Domain.Post: " <> inspect(&1)))

    new_posts
    |> Enum.map(&respond_to/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.each(fn post -> PostRepository.send_post(state.repo, post) end)

    last_seen_post =
      new_posts
      |> Enum.max_by(& &1.timestamp, fn -> %{} end)
      |> Map.get(:id, state.last_seen_post)

    Logger.debug("Latest: #{state.last_seen_post || "∅"} → #{last_seen_post}")
    %{state | last_seen_post: last_seen_post}
  end
end
