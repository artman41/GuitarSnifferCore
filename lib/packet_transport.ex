defmodule GuitarSnifferCore.PacketTransport do
    use Bitwise, only_operators: true
    require Logger

    defmodule FenderStratocaster do

        defmodule EncoderContainer do
            alias GuitarSnifferCore.PacketTransport.FenderStratocaster.EncodedPacket
            defstruct([
                :buttons,
                :strum,
                :accel,
                :whammy,
                :slider,
                :top_frets,
                :low_frets
            ])

            def create(buttons, strum, accel, whammy, slider, top_frets, low_frets) do
                %EncoderContainer{
                    :buttons => Base.decode16!(buttons),
                    :strum => Base.decode16!(strum),
                    :accel => Base.decode16!(accel),
                    :whammy => Base.decode16!(whammy),
                    :slider => Base.decode16!(slider),
                    :top_frets => Base.decode16!(top_frets),
                    :low_frets => Base.decode16!(low_frets)
                }
            end

            def toEncodedPacket(encoderContainer = %EncoderContainer{}) do
                {top_frets, strum} = parse_frets_strum(encoderContainer.top_frets, encoderContainer.strum)
                low_frets = parse_frets(encoderContainer.low_frets)
                buttons = parse_buttons(encoderContainer.buttons)
                slider = parse_slider(encoderContainer.slider)
                Logger.debug(<<
                    "top: #{inspect top_frets}\n",
                    "low: #{inspect low_frets}\n",
                    "strum: #{inspect strum}\n",
                    "buttons: #{inspect buttons}\n",
                    "slider: #{inspect slider}\n",
                    "accel: #{inspect encoderContainer.accel}\n",
                    "whammy: #{inspect encoderContainer.whammy}\n"
                >>)
                EncodedPacket.create(top_frets, low_frets, strum, buttons, slider, encoderContainer.accel, encoderContainer.whammy)
            end

            defp parse_frets_strum(fretCounter, strumCounter) do
                top_frets0 = parse_frets(fretCounter)
                <<top_frets1 :: binary-size(4), topO :: binary>> = top_frets0
                strum0 = parse_strum(strumCounter)
                <<strumO :: binary-size(1), strum1>> = strum0
                case strumO > topO do
                    true ->
                        {<<top_frets1 :: binary, strumO :: binary>>, <<strum1>>}
                    false ->
                        {top_frets0, <<strum1>>}
                end
            end

            defp parse_frets(fretCounter0) do
                Logger.debug("\n===\nPARSING FRETS\n===")
                {fretCounter1, orange} = check_value(fretCounter0, :fret_orange)
                {fretCounter2, blue} = check_value(fretCounter1, :fret_blue)
                {fretCounter3, yellow} = check_value(fretCounter2, :fret_yellow)
                {fretCounter4, red} = check_value(fretCounter3, :fret_red)
                {_fretCounter5, green} = check_value(fretCounter4, :fret_green)
                return = <<
                    green :: binary,
                    red :: binary,
                    yellow :: binary,
                    blue :: binary,
                    orange :: binary
                >>
                Logger.debug("size of frets: #{inspect byte_size(return)}")
                return
            end

            defp parse_buttons(buttonCounter0) do
                Logger.debug("\n===\nPARSING BUTTONS\n===")
                {buttonCounter1, start} = check_value(buttonCounter0, :button_start)
                {_buttonCounter2, menu} = check_value(buttonCounter1, :button_menu)
                return = <<
                    start :: binary,
                    menu :: binary
                >>
                Logger.debug("size of buttons: #{inspect byte_size(return)}")
                return
            end

            # returns <<orange, strum>>
            defp parse_strum(strumCounter0) do
                Logger.debug("\n===\nPARSING STRUM\n===")
                return = cond do
                    xor(strumCounter0, get_key(:strum_up)) == <<0>> ->
                        <<0, 2>>;
                    xor(strumCounter0, get_key(:strum_down)) == <<0>> ->
                        <<0, 1>>;
                    true ->
                        {strumCounter1, orange} = check_value(strumCounter0, :fret_orange)
                        cond do
                            xor(strumCounter1, get_key(:strum_up)) == <<0>> ->
                                <<orange :: binary, 2>>;
                            xor(strumCounter1, get_key(:strum_down)) == <<0>> ->
                                <<orange :: binary, 1>>;
                            true ->
                                <<orange :: binary, 0>>;
                        end
                end
                Logger.debug("size of strum: #{inspect byte_size(return)}")
                return
            end

            defp parse_slider(sliderCounter0) do
                Logger.debug("\n===\nPARSING SLIDER\n===")
                return = cond do
                    check_slider_value(sliderCounter0, :slider_pos1) == 1 ->
                        <<1>>;
                    check_slider_value(sliderCounter0, :slider_pos2) == 1 ->
                        <<2>>;
                    check_slider_value(sliderCounter0, :slider_pos3) == 1 ->
                        <<3>>;
                    check_slider_value(sliderCounter0, :slider_pos4) == 1 ->
                        <<4>>;
                    check_slider_value(sliderCounter0, :slider_pos5) == 1 ->
                        <<5>>
                end
                Logger.debug("size of slider: #{inspect byte_size(return)}")
                return
            end

            defp check_slider_value(counter, key) when is_atom(key) do
                {_, is_trueBin} = check_value(counter, key)
                sizeBin = bit_size(is_trueBin)
                <<is_true :: size(sizeBin)>> = is_trueBin
                is_true
            end

            defp check_value(counter, key) when is_atom(key) do
                do_check_value(counter, get_key(key))
            end

            defp do_check_value(<<0>>, <<0>>), do: {<<0>>, <<1>>}
            defp do_check_value(counter, value) do
                {_, retCode} = result = case xor(counter, value) do
                    nCounter when nCounter < counter ->
                        {nCounter, <<1>>};
                    _ ->
                        {counter, <<0>>}
                end
                Logger.debug("\n> Counter: #{inspect counter}\n> Matching Against: #{inspect value}\n> Return: #{inspect retCode}\n")
                result
            end

            defp get_key(key) do
                GuitarSnifferCore.Packet.FenderStratocaster.Keys.create()
                |> Map.get(key)
            end

            defp xor(a, b) when is_binary(a) and is_binary(b) do
                sizeA = bit_size(a)
                sizeB = bit_size(b)

                <<intA :: size(sizeA)>> = a
                <<intB :: size(sizeB)>> = b
                <<intA ^^^ intB>>
            end
        end

        defmodule EncodedPacket do
            defstruct([
                #            r, g, y, b, o
                top_frets: <<0, 0, 0, 0, 0>>,
                #            r, g, y, b, o
                low_frets: <<0, 0, 0, 0, 0>>,
                #            s
                strum:     <<0>>,
                #            m, s
                buttons:   <<0, 0>>,
                #            s
                slider:    <<1>>,
                #            a
                accel:     <<0>>,
                #
                whammy:    <<0>>
            ])

            def create(top, low, strum, buts, slider, accel, whammy) do
                %EncodedPacket{
                    top_frets: top,
                    low_frets: low,
                    strum: strum,
                    buttons: buts,
                    slider: slider,
                    accel: accel,
                    whammy: whammy
                }
            end

            @doc """
                Converts the EncodedPacket struct to a useable 16bit binary

                ## Example

                Return: <<1, 1, 0, 0, 0, 0, 0, 0, 0, 0,  2, 0, 0,  0, 0, 5>>
                        |_____________| |___________|  _|  |__|   |  |  |_
                        Top Frets      Low Frets   __| Buttons _|  |_ Whammy
                                                Strum      Slider  Accel
            """
            def toBinary(encodedPacket = %EncodedPacket{}) do
                return = <<
                    encodedPacket.top_frets :: binary,
                    encodedPacket.low_frets :: binary,
                    encodedPacket.strum :: binary,
                    encodedPacket.buttons :: binary,
                    encodedPacket.accel :: binary,
                    encodedPacket.whammy :: binary,
                    encodedPacket.slider :: binary
                >>
                Logger.debug("size of encoded Packet: #{inspect byte_size(return)}\nencoded packet: #{inspect return}")
                return
            end
        end

    end

end
