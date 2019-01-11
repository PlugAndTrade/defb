use Mix.Config

config :logger, level: :error

config :defb,
  pages_dir: {:system, "PAGES_DIR", "#{File.cwd!()}/pages"}
