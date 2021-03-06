defmodule Defb.HTTP.IngressError do
  require Logger
  # X-Code	HTTP status code retuned by the request
  # X-Format	Value of the Accept header sent by the client
  # X-Original-URI	URI that caused the error
  # X-Namespace	Namespace where the backend Service is located
  # X-Ingress-Name	Name of the Ingress where the backend is defined
  # X-Service-Name	Name of the Service backing the backend
  # X-Service-Port	Port number of the Service backing the backend
  @x_headers ~w(x-code x-format x-original-uri x-namespace x-ingress-name x-service-name x-service-port)

  defstruct [
    :code,
    :format,
    :original_uri,
    :namespace,
    :ingress_name,
    :service_name,
    :service_port
  ]

  def from(%Plug.Conn{req_headers: headers}) do
    params = for {h, v} <- headers, h in @x_headers, do: {normalize(h), v}
    params = set_status_code(params)

    struct(__MODULE__, params)
  end

  defp set_status_code(params) do
    {sc, _} =
      params
      |> Keyword.get(:code, "404")
      |> Integer.parse()

    Keyword.put(params, :code, sc)
  end

  defp normalize(header) do
    header
    |> String.replace_leading("x-", "")
    |> String.replace("-", "_")
    |> String.to_existing_atom()
  end

  def valid?(%__MODULE__{} = ie) do
    ie
    |> Map.from_struct()
    |> Map.values()
    |> Enum.all?(&(not is_nil(&1)))
  end
end
