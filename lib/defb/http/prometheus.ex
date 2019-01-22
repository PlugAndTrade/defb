defmodule Defb.HTTP.Prometheus do
  require Prometheus.Registry

  @blocked_collectors [
    :prometheus_mnesia_collector,
    :prometheus_vm_memory_collector,
    :prometheus_vm_statistics_collector,
    :prometheus_vm_system_info_collector
  ]

  def setup(opts \\ []) do
    Defb.HTTP.Prometheus.Instrumenter.setup(opts)
    Defb.HTTP.Prometheus.MetricsExporter.setup()

    Enum.each(@blocked_collectors, &Prometheus.Registry.deregister_collector(:default, &1))

    :ok
  end
end
