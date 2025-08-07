defmodule OctopusPingTest do
  use ExUnit.Case
  doctest OctopusPing

  test "greets the world" do
    assert OctopusPing.hello() == :world
  end
end
