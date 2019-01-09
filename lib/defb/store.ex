defmodule Defb.Store do
  use GenServer
  require Logger

  alias Defb.HTTP.IngressError
  alias Defb.ServiceError

  @fallback_name Application.get_env(:defb, :fallback_namespace) <> "/" <> Application.get_env(:defb, :fallback_name)

  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{^name, svc_error}] -> {:ok, svc_error}
      [] -> {:error, :not_found}
    end
  end

  def resolve(
        table,
        %IngressError{service_name: nil, namespace: nil, format: format, code: code}
      ) do
    try_resolve(table, @fallback_name, format, code)
  end

  def resolve(
        table,
        %IngressError{service_name: name, namespace: namespace, format: format, code: code}
      ) do
    case try_resolve(table, namespace <> "/" <> name, format, code) do
      %Defb.Page{} = page -> page
      :not_found -> try_resolve(table, @fallback_name, format, code)
    end
  end

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, table, opts)
  end

  def create(server, %ServiceError{} = svc_error) do
    GenServer.call(server, {:create, {ServiceError.full_name(svc_error), svc_error}})
  end

  def replace(server, %ServiceError{} = svc_error) do
    GenServer.call(server, {:replace, {ServiceError.full_name(svc_error), svc_error}})
  end

  def delete(server, %ServiceError{} = svc_error) do
    GenServer.call(server, {:delete, {ServiceError.full_name(svc_error)}})
  end

  def delete(server, name, namespace) do
    GenServer.call(server, {:delete, namespace <> "/" <> name})
  end

  def init(table_name) do
    table = :ets.new(table_name, [:set, :protected, :named_table, read_concurrency: true])

    {:ok, %{table: table}}
  end

  def handle_call({:create, {name, resource}}, _from, %{table: table} = state) do
    result =
      case lookup(table, name) do
        {:ok, _svc_error} -> :ets.update_element(table, name, {2, resource})
        {:error, :not_found} -> :ets.insert(table, {name, resource})
      end

    if result, do: {:reply, {:ok, resource}, state}, else: {:reply, {:error, resource}, state}
  end

  def handle_call({:replace, {name, resource}}, _from, %{table: table} = state) do
    if :ets.update_element(table, name, {2, resource}) do
      {:reply, {:ok, resource}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:delete, name}, _from, %{table: table} = state) do
    _ = :ets.delete(table, name)
    {:reply, :ok, state}
  end

  defp try_resolve(table, name, format, code) do
    with {:ok, %ServiceError{} = svc_error} <- lookup(table, name),
         page when not is_nil(page) <- ServiceError.find_page(svc_error, format, code) do
      page
    else
      {:error, :not_found} -> :not_found
      nil -> :not_found
    end
  end
end
