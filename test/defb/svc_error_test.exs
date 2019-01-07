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

  test "from/1 configmap data is parsed to %File{}", %{svc_error: svc_error} do
    assert length(svc_error.files) > 0
    assert [%Defb.File{} | _tail] = svc_error.files
  end

  test "find_file/2 can find a specific file by content_type & status_code" do
    files = Defb.File.new(@data)
    svc_error = %Defb.SvcError{files: files}
    file = Defb.SvcError.find_file(svc_error, "text/html", 500)

    assert file.status_code == "500"
  end

  test "find_file/2 will return a explicit match before a wildcard match when both exist" do
    files = Defb.File.new(%{"500.html" => "<p></p>", "5xx.html" => "<p></p>"})
    svc_error = %Defb.SvcError{files: files}
    file = Defb.SvcError.find_file(svc_error, "text/html", 500)

    assert file.status_code == "500"
  end

  test "find_file/2 returns the more specific error when there's multiple matches" do
    files = Defb.File.new(%{"5xx.html" => "<p></p>", "50x.html" => "<p></p>"})
    svc_error = %Defb.SvcError{files: files}
    file = Defb.SvcError.find_file(svc_error, "text/html", 500)

    assert file.status_code == "50x"
  end

  test "find_file/2 returns nil when no matches are present" do
    files = Defb.File.new(%{"4xx.html" => "<p></p>"})
    svc_error = %Defb.SvcError{files: files}
    file = Defb.SvcError.find_file(svc_error, "text/html", 500)

    assert Kernel.is_nil(file)
  end

  test "full_name/1 returns name + namespace of the SvcError" do
    svc_error = %Defb.SvcError{name: "test", namespace: "default"}

    assert Defb.SvcError.full_name(svc_error) == "default/test"
  end
end
