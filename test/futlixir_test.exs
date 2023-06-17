defmodule FutlixirTest do
  use ExUnit.Case
  doctest Futlixir

  test "greets the world" do
    assert Futlixir.hello() == :world
  end
end
