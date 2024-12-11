defmodule Mix.Tasks.Sbom.Phx do
  @moduledoc "Genrates bom files for phoenix projects"
  @shortdoc "Generate sbom for phoenix projects"

  use Mix.Task
  require Logger

  @impl Mix.Task
  def run(args) do
    unless node_version(),
      do: Mix.raise("Nodejs not installed on the system, to continue install nodejs")

    unless Application.get_env(:sbom, :cd) do
      raise ArgumentError, """
      Before you run this, you need to setup configurations in config/dev.exs such as:
      config :sbom,
        cyclone_cli: "0.24.0",
        cyclone_npm: "3.10.4",
        cd: Path.expand("../assets", __DIR__),
        bom_location: Path.expand("../priv/static/.well-known/sbom", __DIR__)
      """
    end

    Sbom.Cli.install()

    Mix.Task.run("sbom.cyclonedx", args)

    file =
      if is_phx?() do
        Sbom.Cli.Phx.install()
        Sbom.Cli.Phx.bom() |> Sbom.Cli.merge("bom.xml")
      else
        "bom.xml"
      end

    Sbom.Cli.convert(file)
  end

  def node_version do
    case System.cmd("node", ["--version"]) do
      {v, 0} -> String.trim(v)
      _ -> nil
    end
  end

  def is_phx? do
    File.exists?(Application.get_env(:sbom, :cd) <> "/package.json")
  end
end
