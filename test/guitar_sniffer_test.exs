defmodule GuitarSnifferTest do
  use ExUnit.Case
  doctest GuitarSniffer

  test "greets the world" do
    assert GuitarSniffer.hello() == :world
  end
end
