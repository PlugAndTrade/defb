defmodule Defb.Config do
  def k8s_server(:proxy, conf),
    do: %Kazan.Server{url: Keyword.fetch!(conf, :api_server)}

  def k8s_server(:in_cluster, _conf),
    do: Kazan.Server.in_cluster()
end
