defmodule Defb.HTTP.Prometheus.InstrumenterTest do
  use ExUnit.Case

  alias Defb.HTTP.IngressError
  alias Defb.HTTP.Prometheus.Instrumenter

  @headers [
    {"x-code", "500"},
    {"x-format", "application/json"},
    {"x-original-uri", "/test"},
    {"x-namespace", "default"},
    {"x-ingress-name", "test-ingress"},
    {"x-service-name", "test-service"},
    {"x-service-port", "80"}
  ]

  test "to_labels/1 returns prometheus labels as a list" do
    conn = %Plug.Conn{req_headers: @headers}
    ing = IngressError.from(conn)

    assert [500, "application/json", "default" | _tail] = Instrumenter.to_labels(ing)
  end
end
