defmodule DefbTest do
  use ExUnit.Case
  doctest Defb

  test "greets the world" do
    assert Defb.hello() == :world
  end
end
