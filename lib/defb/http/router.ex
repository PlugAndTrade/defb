defmodule Defb.HTTP.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/healthz" do
    res = "{\"status\": \"ok\"}"

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, res)
  end

  match _ do
    content = "<html><body><p>hello</p></body></html>"

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(404, content)
  end
end
