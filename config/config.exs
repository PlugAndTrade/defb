# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :defb, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:defb, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

config :defb,
  k8s: [
    api_server: {:system, "K8S_API_SERVER", "http://localhost:8001"},
    mode: {:system, :atom, "K8S_MODE", :proxy}
  ],
  pages_dir: {:system, "PAGES_DIR", "/etc/defb/pages"},
  fallback_name: "__FALLBACK__",
  fallback_namespace: "__FALLBACK__",
  annotations_prefix: "default-http-backend",
  label_selector: "app.kubernetes.io/part-of=defb"

config :logger, :console,
  format: "\n[$date$time] [$level] $metadata$levelpad$message\n",
  metadata: [:module, :function]

if File.exists?(Path.join(__DIR__, "#{Mix.env()}.exs")) do
  import_config "#{Mix.env()}.exs"
end
