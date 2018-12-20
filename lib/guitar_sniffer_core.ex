defmodule GuitarSnifferCore.App do
    require Logger

    def start(_type, _args) do
        get_port()
        |> start_ranch()
    end

    defp get_port() do
        Application.get_env(Application.get_application(__MODULE__), :listener, [port: 3000])
        |> Keyword.fetch!(:port)
    end

    defp start_ranch(port) do
        {:ok, _} = :ranch.start_listener(
            :tcp_listener,
            :ranch_tcp,
            [{:port, port}],
            GuitarSnifferCore.PacketHandler,
            [])
    end

end
