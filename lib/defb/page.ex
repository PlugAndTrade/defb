defmodule Defb.Page do
  @m_regex ~r/[x]+/

  @derive [Poison.Encoder]
  defstruct [
    :status_code,
    :content,
    :content_type,
    :ext,
    :multi_match
  ]

  def new(filename, content) do
    [code, ext] = String.split(filename, ".")

    %__MODULE__{
      status_code: code,
      content: content,
      ext: ext,
      content_type: MIME.type(ext),
      multi_match: match_multiple?(code)
    }
  end

  def new(params) when is_map(params) do
    Enum.map(params, fn {filename, content} -> new(filename, content) end)
  end

  def match_code?(%__MODULE__{} = file, code) when is_integer(code),
    do: match_code?(file, Integer.to_string(code))

  def match_code?(%__MODULE__{multi_match: false, status_code: s_code}, code),
    do: s_code == code

  def match_code?(%__MODULE__{status_code: s_code}, code) do
    s_code
    |> String.replace("x", ".{1}")
    |> Regex.compile!()
    |> Regex.match?(code)
  end

  def match_content_type?(%__MODULE__{content_type: ct}, content_type),
    do: ct == content_type

  def match_multiple?(code), do: Regex.match?(@m_regex, code)
end
