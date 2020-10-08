defmodule APDS_9930Test do
  use ExUnit.Case
  doctest APDS_9930

  test "Converting modes" do
    assert APDS_9930.mode(:power) == 0
    assert (:power |> APDS_9930.mode() |> APDS_9930.mode()) == :power
  end

  test "Converting registers" do
    assert APDS_9930.mode(:enable) == 0x80
    assert (:enable |> APDS_9930.mode() |> APDS_9930.mode()) == :enable
  end
end
