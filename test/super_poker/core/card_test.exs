defmodule SuperPoker.Core.CardTest do
  use ExUnit.Case
  doctest SuperPoker.Core.Card
  alias SuperPoker.Core.Card

  test "create a card from string" do
    assert %Card{} = Card.from_string("2S")
    assert %Card{} = Card.from_string("AH")
    assert %Card{} = Card.from_string("TS")
    assert %Card{} = Card.from_string("QD")
  end

  test "card to string" do
    assert "2S" == Card.from_string("2S") |> Card.to_string()
    assert "AH" == Card.from_string("AH") |> Card.to_string()
    assert "KC" == Card.from_string("KC") |> Card.to_string()
    assert "JD" == Card.from_string("JD") |> Card.to_string()
  end

  test "card to emoji string" do
    assert "♠️ 2" == Card.from_string("2S") |> Card.to_emoji_string()
    assert "♥️ J" == Card.from_string("JH") |> Card.to_emoji_string()
    assert "♣️ K" == Card.from_string("KC") |> Card.to_emoji_string()
    assert "♦️ A" == Card.from_string("AD") |> Card.to_emoji_string()
  end

  test "10 is a little special" do
    assert "♥️ 10" == Card.from_string("TH") |> Card.to_emoji_string()
    assert "TH" == Card.from_string("TH") |> Card.to_string()
  end
end
