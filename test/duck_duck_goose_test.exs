defmodule DuckDuckGooseTest do
  use ExUnit.Case
  doctest DuckDuckGoose

  test "greets the world" do
    assert DuckDuckGoose.hello() == :world
  end
end
