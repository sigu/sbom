defmodule Mix.Tasks.Sbom.Install do
  @shortdoc "Install Elixir Sbom"

  use Mix.Task

  def run(_args) do
    Sbom.Cli.install()
  end
end
