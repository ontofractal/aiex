defmodule AIexTest do
  use ExUnit.Case
  doctest AIex

  test "greets the world" do
    assert AIex.hello() == :world
  end
end
