defmodule Defb.Registry do
  use GenServer
  require Logger

  alias Defb.SvcError

  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{^name, svc_error}] -> {:ok, svc_error}
      [] -> {:error, :not_found}
    end
  end

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, table, opts)
  end

  def create(server, %SvcError{} = svc_error) do
    GenServer.call(server, {:create, {SvcError.full_name(svc_error), svc_error}})
  end

  def replace(server, %SvcError{} = svc_error) do
    GenServer.call(server, {:replace, {SvcError.full_name(svc_error), svc_error}})
  end

  def delete(server, %SvcError{} = svc_error) do
    GenServer.call(server, {:delete, {SvcError.full_name(svc_error)}})
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
end
