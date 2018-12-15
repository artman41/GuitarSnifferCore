defmodule GuitarSnifferCore.ErrorHandler do
    require Logger

    def throw_err(msg) do
        Logger.error(msg)
        {:error, msg}
    end

end
