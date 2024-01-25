defmodule InaraBotTest do
  use ExUnit.Case
  doctest InaraBot

  test "It should actually do a thing, OK?" do
    assert InaraBot.respond_to("Hey, the Serenity") == "It's just Serenity."
  end
end
