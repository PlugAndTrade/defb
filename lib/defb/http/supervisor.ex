defmodule Defb.HTTP.Supervisor do
  use Supervisor
  require Logger

  @timeout 70_000

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    port = Keyword.get(opts, :port, 4000)

    children = [
      {Defb.HTTP.Prometheus.Boot, []},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Defb.HTTP.Router,
        options: [port: port, timeout: @timeout]
      ),
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Defb.HTTP.Prometheus.MetricsExporter,
        options: [
          port: 3000,
          timeout: @timeout,
          transport_options: [num_acceptors: 10]
        ]
      )
    ]

    Logger.info(fn -> "Starting HTTP server on port #{port}" end,
      ansi_color: :magenta
    )

    Supervisor.init(children, strategy: :one_for_one)
  end
end
