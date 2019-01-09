defmodule Defb.SvcError do
  alias Kazan.Apis.Core.V1.ConfigMap

  @derive [Poison.Encoder]
  defstruct name: nil, namespace: nil, pages: []

  def from(%ConfigMap{metadata: metadata, data: data}) do
    pages = Defb.Page.new(data)
    annotations = Defb.SvcError.Annotations.parse(metadata.annotations)
    name = actual_name(annotations, metadata.name)

    %__MODULE__{
      name: name,
      namespace: metadata.namespace,
      pages: pages
    }
  end

  def find_page(%__MODULE__{pages: pages}, content_type, status_code) do
    pages
    |> Enum.filter(
      &(Defb.Page.match_content_type?(&1, content_type) and Defb.Page.match_code?(&1, status_code))
    )
    |> Enum.sort_by(& &1.status_code)
    |> List.first()
  end

  def full_name(%__MODULE__{name: name, namespace: namespace}),
    do: namespace <> "/" <> name

  defp actual_name(%{alternate_name: a_name}, name) when not is_nil(a_name),
    do: a_name

  defp actual_name(_annotations, name), do: name
end
