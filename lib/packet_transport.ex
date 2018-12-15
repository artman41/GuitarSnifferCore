defmodule GuitarSnifferCore.PacketTransport do
    use Bitwise, only_operators: true

    defmodule EncoderContainer do
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
            IO.puts(<<
                "top: #{inspect top_frets}\n",
                "strum: #{inspect strum}\n",
                "low: #{inspect low_frets}\n",
                "buttons: #{inspect buttons}\n",
                "slider: #{inspect slider}\n"
            >>)
            return = <<
                top_frets :: binary,
                low_frets :: binary,
                strum :: binary,
                buttons :: binary,
                encoderContainer.accel :: binary,
                encoderContainer.whammy :: binary,
                slider :: binary
            >>
            IO.puts("size of encoded Packet: #{inspect byte_size(return)}\nencoded packet: #{inspect return}")
            return
        end

        defp parse_frets_strum(fretCounter, strumCounter) do
            top_frets0 = parse_frets(fretCounter)
            <<topO :: binary-size(1), top_frets1 :: binary>> = top_frets0
            strum0 = parse_strum(strumCounter)
            <<strumO :: binary-size(1), strum1>> = strum0
            case strumO > topO do
                true ->
                    {<<strumO, top_frets1>>, <<strum1>>}
                false ->
                    {top_frets0, <<strum1>>}
            end
        end

        defp parse_frets(fretCounter0) do
            IO.puts("\n===\nPARSING FRETS\n===")
            {fretCounter1, green} = check_value(fretCounter0, :fret_green)
            {fretCounter2, red} = check_value(fretCounter1, :fret_red)
            {fretCounter3, yellow} = check_value(fretCounter2, :fret_yellow)
            {fretCounter4, blue} = check_value(fretCounter3, :fret_blue)
            {_fretCounter5, orange} = check_value(fretCounter4, :fret_orange)
            return = <<
                green :: binary,
                red :: binary,
                yellow :: binary,
                blue :: binary,
                orange :: binary
            >>
            IO.puts("size of frets: #{inspect byte_size(return)}")
            return
        end

        defp parse_buttons(buttonCounter0) do
            IO.puts("\n===\nPARSING BUTTONS\n===")
            {buttonCounter1, start} = check_value(buttonCounter0, :button_start)
            {_buttonCounter2, menu} = check_value(buttonCounter1, :button_menu)
            return = <<
                start :: binary,
                menu :: binary
            >>
            IO.puts("size of buttons: #{inspect byte_size(return)}")
            return
        end

        # returns <<orange, strum>>
        defp parse_strum(strumCounter0) do
            IO.puts("\n===\nPARSING STRUM\n===")
            return = cond do
                xor(strumCounter0, get_key(:strum_up)) ->
                    <<0, 2>>;
                    xor(strumCounter0, get_key(:strum_down)) ->
                    <<0, 1>>;
                true ->
                    {strumCounter1, orange} = check_value(strumCounter0, :fret_orange)
                    cond do
                        xor(strumCounter1, get_key(:strum_up)) ->
                            <<orange :: binary, 2>>;
                        xor(strumCounter1, get_key(:strum_down)) ->
                            <<orange :: binary, 1>>;
                        true ->
                            <<orange :: binary, 0>>;
                    end
            end
            IO.puts("size of strum: #{inspect byte_size(return)}")
            return
        end

        defp parse_slider(sliderCounter0) do
            IO.puts("\n===\nPARSING SLIDER\n===")
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
            IO.puts("size of slider: #{inspect byte_size(return)}")
            return
        end

        defp check_slider_value(counter, key) when is_atom(key) do
            {_, is_trueBin} = check_value(counter, key)
            sizeBin = bit_size(is_trueBin)
            <<is_true :: size(sizeBin)>> = is_trueBin
            is_true
        end

        defp check_value(counter, key) when is_atom(key) do
            {_, retCode} = result = case xor(counter, get_key(key)) do
                nCounter when nCounter < counter ->
                    {nCounter, <<1>>};
                _ ->
                    {counter, <<0>>}
            end
            IO.puts("> Counter: #{inspect counter}\n> Matching Against: #{inspect get_key(key)}\n> Return: #{inspect retCode}\n")
            result
        end

        defp get_key(key) do
            GuitarSnifferCore.Packet.Keys.create()
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
            #            m, s
            buttons:   <<0, 0>>,
            #            o, s
            strum:     <<0, 0>>
        ])

        def toBinary(encodedPacket) when encodedPacket == %EncodedPacket{} do

        end
    end

end
