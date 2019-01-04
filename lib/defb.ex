defmodule Defb do
  use Application
  require Logger

  @boot_msg "[Defb] default-backend started"

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Defb.HTTP.Supervisor, port: 4000}
    ]

    Logger.info(fn -> "#{@boot_msg}" end, ansi_color: :magenta)

    Supervisor.start_link(children, strategy: :one_for_one, name: Defb.Supervisor)
  end
end
