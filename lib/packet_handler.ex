defmodule GuitarSnifferCore.PacketHandler do
    @behaviour :ranch_protocol
    require Logger

    defp handle(data) do
        x = GuitarSnifferCore.Packet.decode(data)
        case x do
            {:error, _msg} ->
                GuitarSnifferCore.PacketTransport.FenderStratocaster.EncodedPacket.create()
                |> GuitarSnifferCore.PacketTransport.FenderStratocaster.EncodedPacket.toBinary()
            {:ok, msg} ->
                msg
        end
    end

    def start_link(ref, _socket, transport, opts) do
        pid = spawn_link(__MODULE__, :init, [ref, transport, opts])
        {:ok, pid}
    end

    def init(ref, transport, _opts = []) do
        {:ok, socket} = :ranch.handshake(ref)
        loop(socket, transport)
    end

    def loop(socket, transport) do
        case transport.recv(socket, 0, :infinity) do
            {:ok, data} when data != <<4>> ->
                hData = handle(data)
                IO.puts("hData: #{inspect hData}")
                transport.send(socket, hData)
                loop(socket, transport)
            _ ->
                :ok = transport.close(socket)
        end
    end

end
