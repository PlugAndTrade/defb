defmodule Defb.HTTP.Router do
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  alias Defb.HTTP.IngressError

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  @ok ~s({"status": "ok"})
  @default_response "404 - default backend"
  @store Defb.Store

  get "/healthz" do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, @ok)
  end

  get "/introspect/:namespace/:name" do
    key = Defb.ServiceError.full_name(namespace, name)

    {status_code, response} =
      case Defb.Store.lookup(@store, key) do
        {:ok, resource} -> {200, resource}
        {:error, :not_found} -> {404, %{"status" => "#{key} does not exist"}}
      end

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status_code, Poison.encode!(response))
  end

  match _ do
    %IngressError{code: status_code} = ing_err = IngressError.from(conn)

    {content_type, content} =
      case Defb.Store.resolve(@store, ing_err) do
        %Defb.Page{content: content, content_type: ct} ->
          {ct, content}

        # TODO fix
        :not_found ->
          {"text/plain", @default_response}
      end

    conn
    |> Plug.Conn.put_resp_content_type(content_type)
    |> Plug.Conn.send_resp(status_code, content)
  end
end
