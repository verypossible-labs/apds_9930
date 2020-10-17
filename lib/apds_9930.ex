defmodule APDS_9930 do
  use GenServer

  alias Circuits.I2C

  @address 0x39

  @registers [
    enable: 0x00,
    atime: 0x01,
    ptime: 0x02,
    wtime: 0x03,
    ailtl: 0x04,
    ailth: 0x05,
    aihtl: 0x06,
    aihtl: 0x07,
    piltl: 0x08,
    pilth: 0x09,
    pihtl: 0x0a,
    pihth: 0x0b,
    pers: 0x0c,
    config: 0x0d,
    ppulse: 0x0e,
    control: 0x0f,
    id: 0x12,
    status: 0x13,
    ch0datal: 0x14,
    ch0datah: 0x15,
    ch1datal: 0x16,
    ch1datah: 0x17,
    pdatal: 0x18,
    pdatah: 0x19,
    poffset: 0x1e
  ]

  @modes [
    power: 0,
    ambient_light: 1,
    proximity: 2,
    wait: 3,
    ambient_light_int: 4,
    proximity_int: 5,
    sleep_after_int: 6,
    all: 7
  ]

  @clear_prox_int 0xE5
  @clear_als_int 0xE6
  @clear_all_int 0xE7

  @default_atime 0xED
  @default_wtime 0xFF
  @default_ptime 0xFF
  @default_ppulse 0x08

  @default_poffset 0
  @default_config 0
  @default_pers 0xF0
  @default_control 0x24

  @default_prox_int_low 0
  @default_prox_int_high 50

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def set_mode(pid, mode, enable?) do
    GenServer.call(pid, {:set_mode, mode, enable?})
  end

  def set_modes(pid, modes) do
    GenServer.call(pid, {:set_modes, modes})
  end

  def get_mode(pid, mode) do
    GenServer.call(pid, {:get_mode, mode})
  end

  def get_modes(pid) do
    GenServer.call(pid, :get_modes)
  end

  def read_channel0_data(pid) do
    GenServer.call(pid, :read_channel0_data)
  end

  def read_channel1_data(pid) do
    GenServer.call(pid, :read_channel1_data)
  end

  def read_proximity_data(pid) do
    GenServer.call(pid, :read_proximity_data)
  end

  def set_prox_int_low(pid, prox_low) do
    GenServer.call(pid, {:set_prox_int_low, prox_low})
  end

  def set_prox_int_high(pid, prox_high) do
    GenServer.call(pid, {:set_prox_int_high, prox_high})
  end

  def clear_prox_int(pid) do
    GenServer.call(pid, :clear_prox_int)
  end

  def clear_als_int(pid) do
    GenServer.call(pid, :clear_als_int)
  end

  def clear_all_int(pid) do
    GenServer.call(pid, :clear_all_int)
  end

  def read_register(pid, reg, len \\ 1) do
    GenServer.call(pid, {:read_reg, reg, len})
  end

  def init(opts) do
    bus_name = opts[:bus_name] || raise "Missing required key `bus_name`"
    {:ok, i2c} = I2C.open(bus_name)
    {:ok, i2c, {:continue, nil}}
  end

  def handle_continue(nil, i2c) do
    with :ok <- write_register(i2c, :enable, <<0x00>>),
      :ok <- write_register(i2c, :atime, <<@default_atime>>),
      :ok <- write_register(i2c, :wtime, <<@default_wtime>>),
      :ok <- write_register(i2c, :wtime, <<@default_ptime>>),
      :ok <- write_register(i2c, :ppulse, <<@default_ppulse>>),
      :ok <- write_register(i2c, :poffset, <<@default_poffset>>),
      :ok <- write_register(i2c, :config, <<@default_config>>),
      :ok <- write_register(i2c, :pers, <<@default_pers>>),
      :ok <- write_register(i2c, :control, <<@default_control>>)
      do

    end
    {:noreply, i2c}
  end

  def handle_call({:read_reg, reg, len}, _from, i2c) do
    {:reply, do_read_register(i2c, reg, len), i2c}
  end

  def handle_call({:set_mode, mode, enable}, _from, i2c) do
    reply =
      with {:ok, modes} <- do_read_register(i2c, :enable),
          modes <- decode_modes(modes),
          modes <- Keyword.put(modes, mode, enable),
          modes <- encode_modes(modes) do

        write_register(i2c, :enable, modes)
      end
    {:reply, reply, i2c}
  end

  def handle_call({:set_modes, modes}, _from, i2c) do
    {:reply, do_set_modes(modes, i2c), i2c}
  end

  def handle_call({:get_mode, mode}, _from, i2c) do
    reply =
      with {:ok, modes} <- do_read_register(i2c, :enable) do
      modes = decode_modes(modes)
        Keyword.fetch(modes, mode)
      end
    {:reply, reply, i2c}
  end

  def handle_call(:get_modes, _from, i2c) do
    reply =
      with {:ok, modes} <- do_read_register(i2c, :enable) do
        decode_modes(modes)
      end
    {:reply, reply, i2c}
  end

  def handle_call(:read_channel0_data, _from, i2c) do
    {:reply, do_read_register(i2c, :ch0datal, 2), i2c}
  end

  def handle_call(:read_channel1_data, _from, i2c) do
    {:reply, do_read_register(i2c, :ch1datal, 2), i2c}
  end

  def handle_call(:read_proximity_data, _from, i2c) do
    {:reply, do_read_register(i2c, :pdatal, 2), i2c}
  end

  def handle_call({:set_prox_int_low, prox_int_low}, _from, i2c) do
    {:reply, write_register(i2c, :piltl, <<prox_int_low>>), i2c}
  end

  def handle_call({:set_prox_int_high, prox_int_high}, _from, i2c) do
    {:reply, write_register(i2c, :pihtl, <<prox_int_high>>), i2c}
  end

  def handle_call(:clear_prox_int, _from, i2c) do
    {:reply, write_byte(i2c, <<@clear_prox_int>>), i2c}
  end

  def handle_call(:clear_als_int, _from, i2c) do
    {:reply, write_byte(i2c, <<@clear_als_int>>), i2c}
  end

  def handle_call(:clear_all_int, _from, i2c) do
    {:reply, write_byte(i2c, <<@clear_all_int>>), i2c}
  end

  def decode_modes(<<_ :: 1, sleep_after_int :: 1, proximity_int :: 1, ambient_light_int :: 1, wait :: 1, proximity :: 1, ambient_light :: 1, power :: 1>>) do
    [
      power: int_to_bool(power),
      ambient_light: int_to_bool(ambient_light),
      proximity: int_to_bool(proximity),
      wait: int_to_bool(wait),
      ambient_light_int: int_to_bool(ambient_light_int),
      proximity_int: int_to_bool(proximity_int),
      sleep_after_int: int_to_bool(sleep_after_int)
    ]
  end

  def encode_modes(modes) do
    <<
      0 :: 1,
      bool_to_int(modes[:sleep_after_int]) :: 1,
      bool_to_int(modes[:proximity_int]) :: 1,
      bool_to_int(modes[:ambient_light_int]) :: 1,
      bool_to_int(modes[:wait]) :: 1,
      bool_to_int(modes[:proximity]) :: 1,
      bool_to_int(modes[:ambient_light]) :: 1,
      bool_to_int(modes[:power]) :: 1
    >>
  end

  def modes(), do: @modes
  def mode(mode) when is_atom(mode),
    do: modes()[mode]
  def mode(mode) when is_integer(mode),
    do: find_by_value(modes(), mode)

  def registers(), do: @registers
  def register(register) when is_atom(register),
    do: registers()[register]
  def register(register) when is_binary(register),
    do: find_by_value(registers(), register)

  defp find_by_value(list, value) do
    Enum.find(list, {nil, nil}, &elem(&1, 1) == value) |> elem(0)
  end

  defp int_to_bool(0), do: false
  defp int_to_bool(1), do: true
  defp bool_to_int(false), do: 0
  defp bool_to_int(true), do: 1

  def write_byte(i2c, byte) do
    I2C.write(i2c, @address, byte)
  end

  def write_register(i2c, register, data) do
    register = register(register)
    auto_increment = bool_to_int(byte_size(data) > 1)
    I2C.write(i2c, @address, <<
      1 :: 1,
      auto_increment :: 2,
      register :: 5,
      data :: binary
    >>)
  end

  defp do_read_register(i2c, register, len \\ 1) do
    register = register(register)
    auto_increment = bool_to_int(len > 1)
    I2C.write_read(i2c, @address, <<1 :: 1, auto_increment :: 2, register :: 5>>, len)
  end

  defp do_set_modes(modes, i2c) do
    with modes <- encode_modes(modes) do
      write_register(i2c, :enable, modes)
    end
  end
end
