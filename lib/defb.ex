defmodule Defb do
  use Application
  require Logger

  @boot_msg "[Defb] default-backend started"
  @label_selector "app.kubernetes.io/custom-errors=defb"

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    k8s_conf = Confex.fetch_env!(:defb, :k8s)
    pages_dir = Confex.fetch_env!(:defb, :pages_dir)

    mode = Keyword.fetch!(k8s_conf, :mode)
    conn = Defb.Config.k8s_server(mode, k8s_conf)

    children = [
      {Defb.HTTP.Supervisor, port: 4000},
      {Defb.Registry, name: Defb.Registry},
      {Defb.SvcError.Defaults, [{pages_dir, Defb.Registry}]},
      Defb.Controller.child_spec([
        conn,
        [
          registry: Defb.Registry,
          params: [
            label_selector: @label_selector
          ]
        ]
      ])
    ]

    Logger.info(fn -> "#{@boot_msg}" end, ansi_color: :magenta)

    Supervisor.start_link(children, strategy: :one_for_one, name: Defb.Supervisor)
  end
end
