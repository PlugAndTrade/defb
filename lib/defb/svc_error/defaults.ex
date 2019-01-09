defmodule Defb.SvcError.Defaults do
  use Task
  require Logger
  import Defb.Utils.Dir

  @name "__FALLBACK__"

  def start_link(opts) do
    Task.start_link(__MODULE__, :run, opts)
  end

  def run({path, registry}) do
    files = read_all(path)
    error = %Defb.SvcError{name: @name, namespace: @name, files: files}

    types =
      files
      |> Enum.map(fn {file, _} -> file end)
      |> Enum.join("\n")

    case Defb.Registry.create(registry, error) do
      {:ok, _} ->
        Logger.info(fn ->
          "Fallback templates created successfully! Errors supported:\n#{types}"
        end)

      err ->
        Logger.error(fn -> "Fallback templates could not be created: #{inspect(err)}" end)
    end
  end
end
