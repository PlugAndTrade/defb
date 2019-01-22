defmodule Defb.HTTP.Prometheus.Instrumenter do
  use Prometheus.Metric
  alias Defb.HTTP.IngressError

  @labels [
    :code,
    :format,
    :namespace,
    :ingress_name,
    :service_name,
    :service_port
  ]

  @name :defb_upstream_service_unavailable

  def setup(opts \\ [])

  def setup(_opts) do
    Counter.declare(
      name: @name,
      help: "Ingress upstream services unavailable",
      labels: @labels
    )
  end

  def to_labels(%IngressError{
        code: code,
        format: format,
        namespace: namespace,
        ingress_name: ing_name,
        service_name: svc_name,
        service_port: port
      }) do
    [
      code,
      format,
      namespace,
      ing_name,
      svc_name,
      port
    ]
  end

  def inc(labels), do: Counter.inc(name: @name, labels: labels)
end
