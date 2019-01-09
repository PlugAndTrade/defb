defmodule Defb.HTTP.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Defb.HTTP.Router

  @opts Router.init([])
  @ingress_headers [
    {"x-code", "500"},
    {"x-format", "text/html"},
    {"x-original-uri", "/"},
    {"x-namespace", "default"},
    {"x-ingress-name", "test-ingress"},
    {"x-service-name", "test"},
    {"x-service-port", "80"}
  ]

  test "should respond 200 on /healthz" do
    conn =
      :get
      |> conn("/healthz", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "should return 404 on / when no matches" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end

  describe "ingress error response" do
    test "should return a correct response when ingress headers are set and a match exists" do
      body = "<p>foo</p>"

      resource = %Defb.ServiceError{
        name: "test",
        namespace: "default",
        pages: [
          Defb.Page.new("500.html", body)
        ]
      }

      _ = Defb.Store.delete(Defb.Store, resource)
      {:ok, res} = Defb.Store.create(Defb.Store, resource)

      conn =
        :get
        |> conn("/", "")
        |> add_headers(@ingress_headers)
        |> Router.call(@opts)

      assert conn.status == 500
      assert conn.resp_body == body
    end

    test "should return a default response when there's no match" do
      conn =
        :get
        |> conn("/", "")
        |> add_headers([{"x-code", "400"}])
        |> Router.call(@opts)

      assert conn.status == 400
    end
  end

  defp add_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {h, v}, conn ->
      put_req_header(conn, h, v)
    end)
  end
end
