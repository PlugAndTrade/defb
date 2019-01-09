defmodule Defb.PageTest do
  use ExUnit.Case

  @html_content "<html></html>"
  @json_content ~s({"foo": "bar"})

  test "new/2 returns based on a pagename and content" do
    assert %Defb.Page{} = page = Defb.Page.new("500.html", @html_content)

    assert page.status_code == "500"
    assert page.content == @html_content
    assert page.content_type == "text/html"
    assert page.ext == "html"
    assert page.multi_match? == false
  end

  test "new/2 should return a %Page{} with multi_match when using `xx` patterns" do
    assert %Defb.Page{multi_match?: true} = page = Defb.Page.new("5xx.html", @html_content)
  end

  test "new/2 can handle different content types" do
    assert %Defb.Page{} = page = Defb.Page.new("5xx.json", @json_content)
    assert page.content_type == "application/json"
    assert page.ext == "json"
    assert page.multi_match? == true
  end

  test "new/1 with a map returns a list of %Page{}" do
    pages = %{"500.html" => @html_content, "500.json" => @json_content}

    assert pages = Defb.Page.new(pages)
    assert length(pages) > 0
  end

  test "match_code?/2 returns true when exact match between %Page{} and status code" do
    %Defb.Page{} = page = Defb.Page.new("500.json", @json_content)

    assert Defb.Page.match_code?(page, 500)
    assert Defb.Page.match_code?(page, "500")
  end

  test "match_code?/2 returns true for multimatch pages" do
    %Defb.Page{} = page = Defb.Page.new("5xx.json", @json_content)

    assert Defb.Page.match_code?(page, 500)
    assert Defb.Page.match_code?(page, "500")
  end

  test "match_code?/2 returns false for multimatch pages when not all patterns match" do
    %Defb.Page{} = page = Defb.Page.new("51x.json", @json_content)

    refute Defb.Page.match_code?(page, 500)
    refute Defb.Page.match_code?(page, "500")
  end

  test "match_code?/2 returns true for multimatch pages all wildcards are used" do
    %Defb.Page{} = page = Defb.Page.new("51x.json", @json_content)

    refute Defb.Page.match_code?(page, 500)
    refute Defb.Page.match_code?(page, "500")
  end
end
