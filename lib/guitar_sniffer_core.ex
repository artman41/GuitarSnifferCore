defmodule GuitarSnifferCore.App do
    require Logger

    def start(_type, _args) do
        start_cowboy(8080)
    end

    def start_cowboy(port) do
        dispatch_config = :cowboy_router.compile([
            {:_, [
                {"/packet", GuitarSnifferCore.PacketHandler, []}
            ]}
        ])

        opts = [port: port]
        env = %{dispatch: dispatch_config}

        {:ok, _} = :cowboy.start_clear(:http, opts, %{env: env})
    end

end
