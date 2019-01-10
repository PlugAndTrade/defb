defmodule Defb do
  use Application
  require Logger

  @boot_msg "[Defb] default-http-backend defb started"
  @label_selector Application.get_env(:defb, :label_selector)

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    k8s_conf = Confex.fetch_env!(:defb, :k8s)
    pages_dir = Confex.fetch_env!(:defb, :pages_dir)

    mode = Keyword.fetch!(k8s_conf, :mode)
    conn = k8s_server(mode, k8s_conf)

    children = [
      {Defb.HTTP.Supervisor, port: 4000},
      {Defb.Store, name: Defb.Store},
      {Defb.ServiceError.Defaults, [{pages_dir, Defb.Store}]},
      Defb.Controller.child_spec([
        conn,
        [
          store: Defb.Store,
          params: [
            label_selector: @label_selector
          ]
        ]
      ])
    ]

    Logger.info(fn -> "#{@boot_msg}" end, ansi_color: :magenta)

    Supervisor.start_link(children, strategy: :one_for_one, name: Defb.Supervisor)
  end

  defp k8s_server(:proxy, conf),
    do: %Kazan.Server{url: Keyword.fetch!(conf, :api_server)}

  defp k8s_server(:in_cluster, _conf),
    do: Kazan.Server.in_cluster()
end
