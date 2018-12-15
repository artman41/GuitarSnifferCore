defmodule GuitarSnifferCore.Packet do
    require Logger
    @moduledoc """
    ### Method
    * skip first 30 bytes
    * get next 7

    ### SECTIONS

    #### 0 : MENU
    XY,
    * X -> Menu Button & Option Button
    * Y -> Green to Blue Frets

    #### 1 : Strum
    XY,
    * X -> Strum & Dpad
    * Y -> Orange Fret

    #### 2 : Acceleration

    #### 3 : Whammy

    #### 4 : Slider

    #### 5 : Top Fret

    #### 6 : Low Fret
    """

    defmacro header, do: "8811A0006245B4F0852C7EED8FFF73006245B4F0852CB001"

    defmodule Keys do
        defstruct ([
            fret_green:   <<0x01>>,
            fret_red:     <<0x02>>,
            fret_yellow:  <<0x04>>,
            fret_blue:    <<0x08>>,
            fret_orange:  <<0x10>>,

            strum_up:     <<0x01>>,
            strum_down:   <<0x02>>,

            slider_pos1:  <<0x00>>,
            slider_pos2:  <<0x10>>,
            slider_pos3:  <<0x20>>,
            slider_pos4:  <<0x30>>,
            slider_pos5:  <<0x40>>,

            button_start: <<0x04>>,
            button_menu:  <<0x08>>,

            dpad_down:    <<0x01>>,
            dpad_up:      <<0x02>>,
            dpad_left:    <<0x04>>,
            dpad_right:   <<0x08>>,
        ])

        def create() do
            %Keys{}
        end
    end

    def is_packet(<<header(), data :: binary>>) when is_binary(data) do
        case byte_size(data) do
            32 ->
                {true, data}
            x ->
                Logger.debug("size is #{x}")
                {false, nil}
        end
    end

    def is_packet(_), do: false

    def decode(data) do
        trimmedData = String.replace(data, ":", "")
        Logger.debug("trimmed: #{inspect trimmedData}")
        case is_packet(trimmedData) do
            {false, _} ->
                GuitarSnifferCore.ErrorHandler.throw_err("invalid data!")
            {true, splitData} ->
                Logger.debug("size: #{byte_size(splitData)}")
                do_decode(splitData)
        end
    end

    defp do_decode(<<_head :: binary-size(12), buttons :: binary-size(2), strum :: binary-size(2), accel :: binary-size(2), whammy :: binary-size(2), slider :: binary-size(2), top_fret :: binary-size(2), low_fret :: binary-size(2), _tail :: binary>>) do
        Logger.info(<<
            "buttons: #{inspect buttons}\n",
            "strum: #{inspect strum}\n",
            "accel: #{inspect accel}\n",
            "whammy: #{inspect whammy}\n",
            "slider: #{inspect slider}\n",
            "top_fret: #{inspect top_fret}\n",
            "low_fret: #{inspect low_fret}\n"
        >>)

        bytes = [
            {"buttons", buttons},
            {"strum", strum},
            {"accel", accel},
            {"whammy", whammy},
            {"slider", slider},
            {"top_fret", top_fret},
            {"low_fret", low_fret}
        ]

        encoderContainer = GuitarSnifferCore.PacketTransport.EncoderContainer.create(buttons, strum, accel, whammy, slider, top_fret, low_fret)

        # values = Enum.map(bytes, &parse_byte/1)
        {:ok, GuitarSnifferCore.PacketTransport.EncoderContainer.toEncodedPacket(encoderContainer)}
    end

    def test_packet(), do: <<0x88, 0x11, 0xA0, 0x00, 0x62, 0x45, 0xB4, 0xF0, 0x85, 0x2C, 0x7E, 0xED, 0x8F, 0xFF, 0x73, 0x00, 0x62, 0x45, 0xB4, 0xF0, 0x85, 0x2C, 0xB0, 0x01, 0x00, 0x00, 0x20, 0x00, 0x1C, 0x0A, 0x30, 0x00, 0x00, 0x00, 0x40, 0x03, 0x00, 0x00, 0x00, 0x00>>
    def test_packet(:string), do: "88:11:A0:00:62:45:B4:F0:85:2C:7E:ED:8F:FF:73:00:62:45:B4:F0:85:2C:B0:01:00:00:20:00:1C:0A:30:00:00:00:40:03:00:00:00:00"
end
