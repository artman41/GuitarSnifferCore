defmodule GuitarSnifferCore.Handlers.FenderStratocaster do
    require Logger
    alias GuitarSnifferCore.PacketTransport.FenderStratocaster.{EncoderContainer, EncodedPacket}
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

    def do_decode(<<_head :: binary-size(12), buttons :: binary-size(2), strum :: binary-size(2), accel :: binary-size(2), whammy :: binary-size(2), slider :: binary-size(2), top_fret :: binary-size(2), low_fret :: binary-size(2), _tail :: binary>>) do
        Logger.debug(<<
            "buttons: #{inspect buttons}\n",
            "strum: #{inspect strum}\n",
            "accel: #{inspect accel}\n",
            "whammy: #{inspect whammy}\n",
            "slider: #{inspect slider}\n",
            "top_fret: #{inspect top_fret}\n",
            "low_fret: #{inspect low_fret}\n"
        >>)

        encoderContainer = EncoderContainer.create(buttons, strum, accel, whammy, slider, top_fret, low_fret)
        encodedPacket = EncoderContainer.toEncodedPacket(encoderContainer)
        {:ok, EncodedPacket.toBinary(encodedPacket)}
    end

    def do_decode(x) do
        GuitarSnifferCore.ErrorHandler.throw_err(inspect x)
    end

end
