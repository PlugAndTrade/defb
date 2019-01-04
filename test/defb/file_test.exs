defmodule Defb.FileTest do
  use ExUnit.Case

  @html_content "<html></html>"
  @json_content ~s({"foo": "bar"})

  test "new/2 returns based on a filename and content" do
    assert %Defb.File{} = file = Defb.File.new("500.html", @html_content)

    assert file.status_code == "500"
    assert file.content == @html_content
    assert file.content_type == "text/html"
    assert file.ext == "html"
    assert file.multi_match? == false
  end

  test "new/2 should return a %File{} with multi_match when using `xx` patterns" do
    assert %Defb.File{multi_match?: true} = file = Defb.File.new("5xx.html", @html_content)
  end

  test "new/2 can handle different content types" do
    assert %Defb.File{} = file = Defb.File.new("5xx.json", @json_content)
    assert file.content_type == "application/json"
    assert file.ext == "json"
    assert file.multi_match? == true
  end

  test "new/1 with a map returns a list of %File{}" do
    files = %{"500.html" => @html_content, "500.json" => @json_content}

    assert files = Defb.File.new(files)
    assert length(files) > 0
  end

  test "match_code?/2 returns true when exact match between %File{} and status code" do
    %Defb.File{} = file = Defb.File.new("500.json", @json_content)

    assert Defb.File.match_code?(file, 500)
    assert Defb.File.match_code?(file, "500")
  end

  test "match_code?/2 returns true for multimatch files" do
    %Defb.File{} = file = Defb.File.new("5xx.json", @json_content)

    assert Defb.File.match_code?(file, 500)
    assert Defb.File.match_code?(file, "500")
  end

  test "match_code?/2 returns false for multimatch files when not all patterns match" do
    %Defb.File{} = file = Defb.File.new("51x.json", @json_content)

    refute Defb.File.match_code?(file, 500)
    refute Defb.File.match_code?(file, "500")
  end

  test "match_code?/2 returns true for multimatch files all wildcards are used" do
    %Defb.File{} = file = Defb.File.new("51x.json", @json_content)

    refute Defb.File.match_code?(file, 500)
    refute Defb.File.match_code?(file, "500")
  end
end
