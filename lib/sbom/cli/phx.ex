defmodule Sbom.Cli.Phx do
  require Logger

  def install do
    version = Application.get_env(:sbom, :cyclone_npm) || "3.10.4"

    case bin_version() do
      {:ok, ^version} -> Logger.debug("Already installed version " <> version)
      _ -> do_install(version)
    end
  end

  defp do_install(version) do
    Logger.debug("Installing npm bom generator version " <> version)

    case System.cmd("npm", ["install", "-D ", "@cyclonedx/bom@" <> version],
           cd: Application.get_env(:sbom, :cd)
         ) do
      {_, 0} ->
        Logger.debug("Successfully installed cyclonedx version #{version} for npm packages")

      {error, _} ->
        Logger.error("There was an error during installation", error: error)
    end
  end

  def bin_version do
    with true <- File.exists?(bin_path()),
         {result, 0} <- System.cmd(bin_path(), ["--version"]) do
      {:ok, result |> String.trim()}
    else
      _ -> :error
    end
  end

  def bin_path do
    Application.get_env(:sbom, :cd) <> "/node_modules/@cyclonedx/bom/bin/make-bom.js"
  end

  def bom do
    path = Application.get_env(:sbom, :cd)
    Logger.debug("generating node modules bom")

    res =
      System.cmd(
        path <> "/node_modules/@cyclonedx/bom/bin/make-bom.js",
        ["--output=../bom_phx.xml"],
        cd: path
      )

    case res do
      {_, 0} ->
        Logger.debug("Successfully generated bom file")
        "bom_phx.xml"

      _ ->
        Logger.error("Failed to generate node modules bom file")
        :error
    end
  end
end
