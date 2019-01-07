defmodule Defb.RegistryTest do
  use ExUnit.Case
  alias Defb.SvcError
  setup do
    table = :ets.new(:test, [])
    svc_error = %SvcError{name: "test", namespace: "default"}
    {:ok, table: table, svc_error: svc_error}
  end

  test "lookup/2 returns {:ok, resource} when present in table", %{table: table, svc_error: svc_error} do
    assert true = :ets.insert(table, {"default/test", svc_error})
    assert {:ok, ^svc_error} = Defb.Registry.lookup(table, "default/test")
  end

  test "lookup/2 returns {:error, :not_found} when not present in table", %{table: table, svc_error: svc_error} do
    assert true = :ets.insert(table, {"default/test", svc_error})
    assert {:error, :not_found} = Defb.Registry.lookup(table, "default/test2")
  end

  describe "Registry proc" do
    setup context do
      _ = start_supervised!({Defb.Registry, name: context.test})
      svc_error = %SvcError{name: "test", namespace: "default"}
      {:ok, %{table: context.test, svc_error: svc_error}}
    end

    test "create inserts the resource", %{table: table, svc_error: svc_error} do
      assert {:ok, _} = Defb.Registry.create(table, svc_error)
      assert {:ok, ^svc_error} = Defb.Registry.lookup(table, SvcError.full_name(svc_error))
    end

    test "create overwrites previous resource with same name", %{table: table, svc_error: svc_error} do
      new_res = %SvcError{name: "test", namespace: "default", files: ["foo"]}
      assert {:ok, old} = Defb.Registry.create(table, svc_error)
      assert {:ok, new} = Defb.Registry.create(table, new_res)

      assert old.name == new.name
      assert old.namespace == new.namespace
      assert length(old.files) < length(new.files)
    end

    test "replace overwrites previous resource", %{table: table, svc_error: svc_error} do
      new_res = %SvcError{name: "test", namespace: "default", files: ["foo"]}
      assert {:ok, old} = Defb.Registry.create(table, svc_error)
      assert {:ok, new} = Defb.Registry.replace(table, new_res)

      assert old.name == new.name
      assert old.namespace == new.namespace
      assert length(old.files) < length(new.files)
    end

    test "replace with missing resource returns {:error, :not_found}", %{table: table, svc_error: svc_error} do
      assert {:error, :not_found} = Defb.Registry.replace(table, svc_error)
    end

    test "delete returns :ok when present", %{table: table, svc_error: svc_error} do
      assert {:ok, _} = Defb.Registry.create(table, svc_error)
      assert :ok = Defb.Registry.delete(table, svc_error)
    end

    test "delete with namespace/name returns :ok when present", %{table: table, svc_error: svc_error} do
      assert {:ok, _} = Defb.Registry.create(table, svc_error)
      assert :ok = Defb.Registry.delete(table, svc_error.name, svc_error.namespace)
    end

    test "delete with missing resource returns :ok", %{table: table, svc_error: svc_error} do
      assert :ok = Defb.Registry.delete(table, svc_error.name, svc_error.namespace)
    end
  end
end
