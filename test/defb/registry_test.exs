defmodule Defb.StoreTest do
  use ExUnit.Case
  alias Defb.ServiceError

  setup do
    table = :ets.new(:test, [])
    svc_error = %ServiceError{name: "test", namespace: "default"}
    {:ok, table: table, svc_error: svc_error}
  end

  test "lookup/2 returns {:ok, resource} when present in table", %{
    table: table,
    svc_error: svc_error
  } do
    assert true = :ets.insert(table, {"default/test", svc_error})
    assert {:ok, ^svc_error} = Defb.Store.lookup(table, "default/test")
  end

  test "lookup/2 returns {:error, :not_found} when not present in table", %{
    table: table,
    svc_error: svc_error
  } do
    assert true = :ets.insert(table, {"default/test", svc_error})
    assert {:error, :not_found} = Defb.Store.lookup(table, "default/test2")
  end

  describe "Store proc" do
    setup context do
      _ = start_supervised!({Defb.Store, name: context.test})
      svc_error = %ServiceError{name: "test", namespace: "default"}
      {:ok, %{table: context.test, svc_error: svc_error}}
    end

    test "create inserts the resource", %{table: table, svc_error: svc_error} do
      assert {:ok, _} = Defb.Store.create(table, svc_error)
      assert {:ok, ^svc_error} = Defb.Store.lookup(table, ServiceError.full_name(svc_error))
    end

    test "create overwrites previous resource with same name", %{
      table: table,
      svc_error: svc_error
    } do
      new_res = %ServiceError{name: "test", namespace: "default", pages: ["foo"]}
      assert {:ok, old} = Defb.Store.create(table, svc_error)
      assert {:ok, new} = Defb.Store.create(table, new_res)

      assert old.name == new.name
      assert old.namespace == new.namespace
      assert length(old.pages) < length(new.pages)
    end

    test "replace overwrites previous resource", %{table: table, svc_error: svc_error} do
      new_res = %ServiceError{name: "test", namespace: "default", pages: ["foo"]}
      assert {:ok, old} = Defb.Store.create(table, svc_error)
      assert {:ok, new} = Defb.Store.replace(table, new_res)

      assert old.name == new.name
      assert old.namespace == new.namespace
      assert length(old.pages) < length(new.pages)
    end

    test "replace with missing resource returns {:error, :not_found}", %{
      table: table,
      svc_error: svc_error
    } do
      assert {:error, :not_found} = Defb.Store.replace(table, svc_error)
    end

    test "delete returns :ok when present", %{table: table, svc_error: svc_error} do
      assert {:ok, _} = Defb.Store.create(table, svc_error)
      assert :ok = Defb.Store.delete(table, svc_error)
    end

    test "delete with namespace/name returns :ok when present", %{
      table: table,
      svc_error: svc_error
    } do
      assert {:ok, _} = Defb.Store.create(table, svc_error)
      assert :ok = Defb.Store.delete(table, svc_error.name, svc_error.namespace)
    end

    test "delete with missing resource returns :ok", %{table: table, svc_error: svc_error} do
      assert :ok = Defb.Store.delete(table, svc_error.name, svc_error.namespace)
    end
  end
end
