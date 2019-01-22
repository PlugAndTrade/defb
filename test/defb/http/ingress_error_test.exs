defmodule Defb.HTTP.IngressErrorTest do
  use ExUnit.Case

  alias Defb.HTTP.IngressError

  @headers [
    {"x-code", "500"},
    {"x-format", "application/json"},
    {"x-original-uri", "/test"},
    {"x-namespace", "default"},
    {"x-ingress-name", "test-ingress"},
    {"x-service-name", "test-service"},
    {"x-service-port", "80"}
  ]

  test "from/1 should extract custom errors headers from conn" do
    conn = %Plug.Conn{req_headers: @headers}

    assert %IngressError{} = IngressError.from(conn)
  end

  test "from/1 should have all struct values set" do
    conn = %Plug.Conn{req_headers: @headers}

    assert %IngressError{} = ing_err = IngressError.from(conn)
    assert ing_err.code == 500
    assert ing_err.format == "application/json"
    assert ing_err.original_uri == "/test"
    assert ing_err.ingress_name == "test-ingress"
    assert ing_err.service_name == "test-service"
    assert ing_err.service_port == "80"
  end

  test "valid?/1 returns true if all fields are set" do
    conn = %Plug.Conn{req_headers: @headers}

    assert conn
           |> IngressError.from()
           |> IngressError.valid?()
  end

  test "valid?/1 returns false any fields are not set" do
    conn = %Plug.Conn{req_headers: []}

    refute conn
           |> IngressError.from()
           |> IngressError.valid?()
  end
end
