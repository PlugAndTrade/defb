defmodule Defb.MixProject do
  use Mix.Project

  def project do
    [
      app: :defb,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kazan, "~> 0.10"},
      {:confex, "~> 3.3.1"},
      {:mime, "~> 1.2"},
      {:netex,
       git: "https://github.com/drowzy/netex", ref: "2730a3f193cfefafaf2c3323d0b89889b95d0dee"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:distillery, "~> 2.0", runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end