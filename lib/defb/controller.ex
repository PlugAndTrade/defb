defmodule Defb.Controller do
  use Netex.Controller
  require Logger

  alias Kazan.Watcher
  alias Kazan.Apis.Core.V1.{ConfigMap, ConfigMapList}
  alias Kazan.Models.Apimachinery.Meta.V1.ObjectMeta

  @impl true
  def init(opts) do
    Logger.info(fn -> "[#{__MODULE__}] :: K8s controller up!" end, ansi_color: :magenta)

    {:ok,
     %{
       conn: Keyword.fetch!(opts, :conn),
       registry: Keyword.fetch!(opts, :registry)
     }}
  end

  @impl Netex.Controller
  def watch_fn(_resource, config) do
    Logger.info("#{__MODULE__} :: Watch fn #{inspect(config)}")
    Kazan.Apis.Core.V1.watch_config_map_list_for_all_namespaces!(config)
  end

  @impl Netex.Controller
  def list_fn(opts \\ [])

  def list_fn(config) do
    Logger.info("#{__MODULE__} :: list fn #{inspect(config)}")
    Kazan.Apis.Core.V1.list_config_map_for_all_namespaces!(config)
  end

  @impl Netex.Controller
  def handle_added(%Watcher.Event{object: object}, %{registry: registry} = state) do
    resource = Defb.SvcError.from(object)

    case Defb.Registry.create(registry, resource) do
      {:ok, resource} ->
        Logger.info(fn ->
          "#{__MODULE__} :: ADD #{Defb.SvcError.full_name(resource)} successfull!"
        end)

      {:error, reason} ->
        Logger.error(fn ->
          "#{__MODULE__} :: ADD #{Defb.SvcError.full_name(resource)} failed: #{inspect(reason)}"
        end)
    end

    state
  end

  @impl Netex.Controller
  def handle_modified(%Watcher.Event{object: object}, %{registry: registry} = state) do
    resource = Defb.SvcError.from(object)

    case Defb.Registry.replace(registry, resource) do
      {:ok, resource} ->
        Logger.info(fn ->
          "#{__MODULE__} REPLACE :: #{Defb.SvcError.full_name(resource)} successfull!"
        end)

      {:error, reason} ->
        Logger.error(fn ->
          "#{__MODULE__} REPLACE :: #{Defb.SvcError.full_name(resource)} failed: #{inspect(reason)}"
        end)
    end

    state
  end

  @impl Netex.Controller
  def handle_deleted(%Watcher.Event{object: object}, %{registry: registry} = state) do
    resource = Defb.SvcError.from(object)

    Logger.info(fn -> "#{__MODULE__} DELETE :: resource #{Defb.SvcError.full_name(resource)}" end)

    Defb.Registry.delete(registry, resource)

    state
  end

  @impl Netex.Controller
  def handle_sync(%ConfigMapList{items: items}, %{registry: registry} = state) do
    err =
      items
      |> Enum.map(&Defb.Registry.create(registry, Defb.SvcError.from(&1)))
      |> Enum.find(fn {result, _} -> result == :error end)

    case err do
      nil ->
        Logger.info(fn -> "#{__MODULE__} SYNC :: All items synced" end)
        :ok

      {:error, reason} ->
        Logger.error(fn -> "Encountered error #{inspect(reason)}" end)
        :ok
    end

    state
  end
end
