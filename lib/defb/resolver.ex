defmodule Defb.Resolver do
  require Logger
  alias Defb.HTTP.IngressError
  alias Defb.SvcError

  @fallback_name "__FALLBACK__/__FALLBACK"

  def resolve(
        %IngressError{service_name: nil, namespace: nil, format: format, code: code},
        registry
      ) do
    try_resolve(@fallback_name, format, code, registry)
  end

  def resolve(
        %IngressError{service_name: name, namespace: namespace, format: format, code: code},
        registry
      ) do
    case try_resolve(namespace <> "/" <> name, format, code, registry) do
      %Defb.Page{} = page -> page
      :not_found -> try_resolve(@fallback_name, format, code, registry)
    end
  end

  def try_resolve(name, format, code, registry) do
    with {:ok, %SvcError{} = svc_error} <- Defb.Registry.lookup(registry, name),
         page when not is_nil(page) <- SvcError.find_page(svc_error, format, code) do
      page
    else
      {:error, :not_found} -> :not_found
      nil -> :not_found
    end
  end
end
