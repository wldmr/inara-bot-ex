defmodule InaraBot do
  @moduledoc """
  Documentation for `InaraBot`.
  """

  @re ~r/the serenity\b(?!\s+crew|cast|movie|series)/i

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
  @spec respond_to(String.t()) :: String.t() | nil
  def respond_to(msg) do
    if String.match?(msg, @re) do
      "It's just Serenity."
    else
      nil
    end
  end
end
