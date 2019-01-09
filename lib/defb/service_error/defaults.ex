defmodule Defb.ServiceError.Defaults do
  use Task
  require Logger

  import Defb.Utils.Dir

  @name Application.get_env(:defb, :fallback_name)
  @namespace Application.get_env(:defb, :fallback_namespace)

  def start_link(opts) do
    Task.start_link(__MODULE__, :run, opts)
  end

  def run({path, store}) do
    pages = read_all(path)
    error = %Defb.ServiceError{name: @name, namespace: @namespace, pages: pages}

    types =
      pages
      |> Enum.map(fn {file, _} -> file end)
      |> Enum.join("\n")

    case Defb.Store.create(store, error) do
      {:ok, _} ->
        Logger.info(fn ->
          "Fallback templates created successfully! Errors supported:\n#{types}"
        end)

      err ->
        Logger.error(fn -> "Fallback templates could not be created: #{inspect(err)}" end)
    end
  end
end
