defmodule InaraBotTest do
  use ExUnit.Case
  doctest InaraBot

  test "It should actually do a thing, OK?" do
    assert InaraBot.respond_to(%Post{body: "Hey, the Serenity"}) == %Post{body: "> the Serenity\n\nIt's just Serenity."}
  end
end
