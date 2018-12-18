defmodule GuitarSnifferCore.Handlers.DefaultController do
    require Logger
    import GuitarSnifferCore.Packet.Headers

    def do_decode(<<controller_descriptor_input_header(), data :: binary>>) do
        Logger.info("[xbox controller] #{data}")

        {:ok, "XBOX CONTROLLER"}
    end

    def do_decode(data), do: GuitarSnifferCore.ErrorHandler.throw_err("unknown header!\n    #{inspect data}")

end
