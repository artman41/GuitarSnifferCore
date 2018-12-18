defmodule GuitarSnifferCore.PacketHandler do
    require Logger

    def init(req0, opts) do

        :cowboy_req.method(req0)
        |> handle(req0, opts)
    end

    def handle(<<"GET">>, req0, opts) do
        req = :cowboy_req.reply(200, %{"content-type" => "text/html"}, "Incorrect Method!", req0)
        {:ok, req, opts}
    end

    def handle(<<"POST">>, req0, opts) do
        req = case :cowboy_req.has_body(req0) do
            false ->
                :cowboy_req.reply(500, %{"content-type" => "text/html"}, "Body contained no data!", req0)
            true ->
                {:ok, data, req1} = :cowboy_req.read_body(req0)
                {body, req2} = handle_body(data, req1)
                :cowboy_req.reply(200, %{"content-type" => "text/html"}, body, req2)
        end
        {:ok, req, opts}
    end

    def handle_body(data, req) do
        x = GuitarSnifferCore.Packet.decode(data)
        Logger.debug("#{inspect x}")
        case x do
            {:error, msg} ->
                {msg, req}
            {:ok, msg} ->
                {msg, req}
        end

    end

end
