defmodule Defb.HTTP.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  alias Defb.HTTP.IngressError

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/healthz" do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, "{\"status\": \"ok\"}")
  end

  match _ do
    ing_err = IngressError.from(conn)

    {status_code, content_type, content} =
      case Defb.Resolver.resolve(ing_err, Defb.Registry) do
        %Defb.File{content: content, content_type: ct} ->
          {sc, _} = Integer.parse(ing_err.code)
          {sc, ct, content}

        # TODO fix
        :fallback ->
          {404, "text/html", "<html><body><p>hello</p></body></html>"}
      end

    conn
    |> Plug.Conn.put_resp_content_type(content_type)
    |> Plug.Conn.send_resp(status_code, content)
  end
end
