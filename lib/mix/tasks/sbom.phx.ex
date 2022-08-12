defmodule Mix.Tasks.Sbom.Phx do
  @moduledoc "Genrates bom files for phoenix projects"
  @shortdoc "Generate sbom for phoenix projects"

  use Mix.Task
  require Logger

  @impl Mix.Task
  def run(args) do
    Sbom.Cli.install()

    unless File.exists?("bom.xml") do
      Mix.Task.run("sbom.cyclonedx", args)
    end

    Sbom.Cli.Phx.bom()
    |> Sbom.Cli.merge("bom.xml")
    |> Sbom.Cli.convert()
  end
end
