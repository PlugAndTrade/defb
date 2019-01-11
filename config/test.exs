use Mix.Config

config :defb,
  pages_dir: {:system, "PAGES_DIR", "#{File.cwd!()}/pages"}
