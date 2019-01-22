defmodule Defb.HTTP.Prometheus.Boot do
  use Task, restart: :transient
  require Logger

  def start_link(opts) do
    Task.start_link(__MODULE__, :run, [opts])
  end

  def run(opts) do
    Defb.HTTP.Prometheus.setup(opts)
  end
end
