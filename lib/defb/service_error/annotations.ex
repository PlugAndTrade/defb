defmodule Defb.ServiceError.Annotations do
  @prefix Application.get_env(:defb, :annotation_prefix)
  @annotation_keys ~w(alternate-name)

  def parse(annotations) do
    is_defined? = fn
      {_k, nil} -> false
      {_k, _value} -> true
    end

    @annotation_keys
    |> Enum.map(&parse_annotation(annotations, &1))
    |> Enum.filter(is_defined?)
    |> Enum.into(%{})
  end

  defp parse_annotation(annotations, key) do
    full_key = "#{@prefix}/#{key}"
    value = Map.get(annotations, full_key, nil)

    key =
      key
      |> String.replace("-", "_")
      |> String.to_atom()

    {key, value}
  end
end
