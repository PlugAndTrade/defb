defmodule Defb.Utils.Dir do
  def read_all(path) do
    path
    |> File.ls!()
    |> Enum.map(&{&1, File.read!(path <> "/" <> &1)})
    |> Enum.into(%{})
  end
end
