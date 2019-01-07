defmodule Defb.SvcError do
  alias Kazan.Apis.Core.V1.ConfigMap
  defstruct name: nil, namespace: nil, files: []

  def from(%ConfigMap{metadata: metadata, data: data}) do
    files = Defb.File.new(data)
    annotations = Defb.SvcError.Annotations.parse(metadata.annotations)
    name = actual_name(annotations, metadata.name)

    %__MODULE__{
      name: name,
      namespace: metadata.namespace,
      files: files
    }
  end

  def find_file(%__MODULE__{files: files}, content_type, status_code) do
    files
    |> Enum.filter(
      &(Defb.File.match_content_type?(&1, content_type) and Defb.File.match_code?(&1, status_code))
    )
    |> Enum.sort_by(& &1.status_code)
    |> List.first()
  end

  def actual_name(%{alternate_name: a_name}, name) when not is_nil(a_name),
    do: a_name

  def actual_name(_annotations, name), do: name

  def full_name(%__MODULE__{name: name, namespace: namespace}),
    do: namespace <> "/" <> name
end
