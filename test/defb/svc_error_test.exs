defmodule Defb.SvcErrorTest do
  use ExUnit.Case

  alias Defb.SvcError
  alias Kazan.Apis.Core.V1.ConfigMap
  alias Kazan.Models.Apimachinery.Meta.V1.ObjectMeta

  @data %{
    "500.html" => "<p>test</p>"
  }
  @annotations %{}

  setup do
    configmap = %ConfigMap{
      metadata: %ObjectMeta{name: "test", namespace: "default", annotations: @annotations},
      data: @data
    }

    svc_error = SvcError.from(configmap)

    {:ok, svc_error: svc_error}
  end

  test "from/1 turns a configmap to a %SvcError", %{svc_error: svc_error} do
    assert %SvcError{} = svc_error
  end

  test "from/1 sets name & namespace from metadata if no annotations is set", %{
    svc_error: svc_error
  } do
    assert svc_error.name == "test"
    assert svc_error.namespace == "default"
  end

  test "from/1 sets name from configmap annotation when `alternate-name` is set" do
    name = "foobar"

    configmap = %ConfigMap{
      metadata: %ObjectMeta{
        name: "test",
        namespace: "default",
        annotations: %{"nginx-custom-errors/alternate-name" => name}
      },
      data: @data
    }

    svc_error = SvcError.from(configmap)

    assert svc_error.name == name
  end

  test "from/1 configmap data is parsed to %Page{}", %{svc_error: svc_error} do
    assert length(svc_error.pages) > 0
    assert [%Defb.Page{} | _tail] = svc_error.pages
  end

  test "find_page/2 can find a specific page by content_type & status_code" do
    pages = Defb.Page.new(@data)
    svc_error = %Defb.SvcError{pages: pages}
    page = Defb.SvcError.find_page(svc_error, "text/html", 500)

    assert page.status_code == "500"
  end

  test "find_page/2 will return a explicit match before a wildcard match when both exist" do
    pages = Defb.Page.new(%{"500.html" => "<p></p>", "5xx.html" => "<p></p>"})
    svc_error = %Defb.SvcError{pages: pages}
    page = Defb.SvcError.find_page(svc_error, "text/html", 500)

    assert page.status_code == "500"
  end

  test "find_page/2 returns the more specific error when there's multiple matches" do
    pages = Defb.Page.new(%{"5xx.html" => "<p></p>", "50x.html" => "<p></p>"})
    svc_error = %Defb.SvcError{pages: pages}
    page = Defb.SvcError.find_page(svc_error, "text/html", 500)

    assert page.status_code == "50x"
  end

  test "find_page/2 returns nil when no matches are present" do
    pages = Defb.Page.new(%{"4xx.html" => "<p></p>"})
    svc_error = %Defb.SvcError{pages: pages}
    page = Defb.SvcError.find_page(svc_error, "text/html", 500)

    assert Kernel.is_nil(page)
  end

  test "full_name/1 returns name + namespace of the SvcError" do
    svc_error = %Defb.SvcError{name: "test", namespace: "default"}

    assert Defb.SvcError.full_name(svc_error) == "default/test"
  end
end
