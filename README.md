# APDS_9930

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `apds_9930` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:apds_9930, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/apds_9930](https://hexdocs.pm/apds_9930).

# Usage

```elixir
{:ok, left} = Circuits.GPIO.open(117, :input)
{:ok, right} = Circuits.GPIO.open(114, :input)

Circuits.GPIO.read(left)
Circuits.GPIO.read(right)

Circuits.GPIO.set_interrupts(left, :both)
Circuits.GPIO.set_interrupts(right, :both)

{:ok, pid} = APDS_9930.start_link([bus_name: "i2c-0"])
modes = APDS_9930.get_modes(pid)

APDS_9930.set_prox_int_low(pid, 0)
APDS_9930.set_prox_int_high(pid, 25)

modes = modes |> Keyword.put(:power, true) |> Keyword.put(:proximity, true) |> Keyword.put(:proximity_int, true) |> Keyword.put(:ambient_light, true) |> Keyword.put(:wait, true)
APDS_9930.set_modes pid, modes

APDS_9930.read_proximity_data(pid)
APDS_9930.clear_prox_int(pid)

```
