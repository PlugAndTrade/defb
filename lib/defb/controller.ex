defmodule Defb.Controller do
  use Netex.Controller
  require Logger

  alias Kazan.Watcher
  alias Kazan.Apis.Core.V1.ConfigMapList

  @impl true
  def init(opts) do
    %Kazan.Server{url: url} = conn = Keyword.fetch!(opts, :conn)
    store = Keyword.fetch!(opts, :store)

    Logger.debug(fn -> "K8s Controller starting api-server=#{inspect(url)}" end,
      ansi_color: :magenta
    )

    {:ok,
     %{
       conn: conn,
       store: store
     }}
  end

  @impl Netex.Controller
  def watch_fn(_resource, config) do
    Kazan.Apis.Core.V1.watch_config_map_list_for_all_namespaces!(config)
  end

  @impl Netex.Controller
  def list_fn(opts \\ [])

  def list_fn(config) do
    Kazan.Apis.Core.V1.list_config_map_for_all_namespaces!(config)
  end

  @impl Netex.Controller
  def handle_added(%Watcher.Event{object: object}, %{store: store} = state) do
    resource = Defb.ServiceError.from(object)

    case Defb.Store.create(store, resource) do
      {:ok, resource} ->
        Logger.debug(fn ->
          "action=ADD #{Defb.ServiceError.full_name(resource)}"
        end)

      {:error, reason} ->
        Logger.error(fn ->
          "action=ADD #{Defb.ServiceError.full_name(resource)} error=#{inspect(reason)}"
        end)
    end

    state
  end

  @impl Netex.Controller
  def handle_modified(%Watcher.Event{object: object}, %{store: store} = state) do
    resource = Defb.ServiceError.from(object)

    case Defb.Store.replace(store, resource) do
      {:ok, resource} ->
        Logger.debug(fn ->
          "action=REPLACE #{Defb.ServiceError.full_name(resource)}"
        end)

      {:error, reason} ->
        Logger.error(fn ->
          "action=REPLACE :: #{Defb.ServiceError.full_name(resource)} error=#{inspect(reason)}"
        end)
    end

    state
  end

  @impl Netex.Controller
  def handle_deleted(%Watcher.Event{object: object}, %{store: store} = state) do
    resource = Defb.ServiceError.from(object)

    Logger.debug(fn ->
      "action=DELETE #{Defb.ServiceError.full_name(resource)}"
    end)

    Defb.Store.delete(store, resource)

    state
  end

  @impl Netex.Controller
  def handle_sync(%ConfigMapList{items: items}, %{store: store} = state) do
    svc_errors =
      for item <- items, do: Defb.Store.create(store, Defb.ServiceError.from(item))

    err = Enum.find(svc_errors, fn {result, _} -> result == :error end)

    case err do
      nil ->
        configs = Enum.map(svc_errors, fn {_, c} -> c end)
        Logger.debug(fn -> "action=sync svcs=\n#{pp_svc_errors(configs)}" end)
        :ok

      {:error, reason} ->
        Logger.error(fn -> "action=sync error=#{inspect(reason)}" end)
        :ok
    end

    state
  end

  defp pp_svc_errors(svc_errors) do
    svc_errors
    |> Enum.map(&Defb.ServiceError.full_name(&1))
    |> Enum.join("\n")
  end
end
