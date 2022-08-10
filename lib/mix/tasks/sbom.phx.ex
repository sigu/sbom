defmodule Mix.Tasks.Sbom.Phx do
  @shortdoc "Generate sbom for node packages"

  use Mix.Task
  require Logger

  def run(_args) do
    Sbom.Cli.install()
    path = Application.get_env(:sbom, :cd)
    Logger.debug("generating node modules bom")

    res =
      System.cmd(
        path <> "/node_modules/@cyclonedx/bom/bin/make-bom.js",
        ["--output=../bom_phx.xml"],
        cd: path
      )

    case res do
      {_, 0} -> Logger.debug("Successfully generated bom file")
      _ -> Logger.error("Failed to generate node modules bom file")
    end

    Logger.debug("Merging the two files")
    Sbom.Cli.merge("bom_phx.xml", "bom.xml")
    Sbom.Cli.convert("bom_merged.xml")
  end
end
