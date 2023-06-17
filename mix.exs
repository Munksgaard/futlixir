defmodule Futlixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :futlixir,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [
        main_module: Futlixir.CLI,
        comment: "A sample escript"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
