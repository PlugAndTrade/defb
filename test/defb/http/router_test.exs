defmodule Defb.HTTP.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias Defb.HTTP.Router

  @opts Router.init([])

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
end
