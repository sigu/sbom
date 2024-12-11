defmodule Sbom.Cli do
  require Logger

  def install do
    version = Application.get_env(:sbom, :cyclone_cli) || "0.24.0"

    case bin_version() do
      {:ok, ^version} ->
        Logger.debug("Skipping, already installed version #{version}")

      _ ->
        name = "cyclonedx-#{target()}"
        url = "https://github.com/CycloneDX/cyclonedx-cli/releases/download/v#{version}/#{name}"
        bin_path = bin_path()
        binary = fetch_body!(url)
        File.mkdir_p!(Path.dirname(bin_path))
        File.write!(bin_path, binary, [:binary])
        File.chmod(bin_path, 0o755)
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

  @doc """
  Returns the path to the executable.
  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    Path.expand("_build/cyclonedx-cli-#{target()}")
  end

  # Available targets:
  # cyclonedx-linux-arm
  # cyclonedx-linux-arm64
  # cyclonedx-linux-x64
  # cyclonedx-osx-arm64
  # cyclonedx-osx-x64
  # cyclonedx-win-arm.exe
  # cyclonedx-win-arm64.exe
  # cyclonedx-win-x64.exe
  # cyclonedx-win-x86.exe
  defp target do
    arch_str = :erlang.system_info(:system_architecture)
    [arch | _] = arch_str |> List.to_string() |> String.split("-")

    case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
      {{:win32, _}, _arch, 64} ->
        "windows-x64.exe"

      {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) ->
        "osx-arm64"

      {{:unix, :darwin}, "x86_64", 64} ->
        "osx-x64"

      {{:unix, :linux}, "aarch64", 64} ->
        "linux-arm64"

      {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) ->
        "linux-x64"

      {_os, _arch, _wordsize} ->
        raise "cyclondedx cli is not available for architecture: #{arch_str}"
    end
  end

  defp fetch_body!(url) do
    url = String.to_charlist(url)
    Logger.debug("Downloading cyclonedx cli from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
      Logger.debug("Using HTTP_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
    end

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = CAStore.file_path() |> String.to_charlist()

    http_options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile,
        depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise "couldn't fetch #{url}: #{inspect(other)}"
    end
  end

  def merge(:error, file2), do: file2

  def merge(file1, file2) do
    if File.exists?(file1) and File.exists?(file2) do
      do_merge(file1, file2)
    else
      missing_file = if File.exists?(file1), do: file2, else: file1
      Logger.error("Could not find file " <> missing_file)
      :error
    end
  end

  defp do_merge(file1, file2) do
    Logger.debug("Merging the two files - #{file1} and #{file2}...")
    input_files = file1 <> " " <> file2
    output_filename = 'bom_merged.xml'

    cmd =
      String.to_charlist(bin_path()) ++
        ' merge --input-files=' ++
        String.to_charlist(input_files) ++
        ' --output-file=' ++
        output_filename ++
        ' --name=' ++
        to_charlist(name()) ++
        ' --version=' ++ to_charlist(version())

    cmd |> :os.cmd() |> Logger.debug()
    output_filename |> to_string
  end

  def convert(
        input_file,
        version \\ "1_3",
        output_formats \\ ["xml", "json", "spdxjson"]
      )
      when is_binary(input_file) do
    for output <- output_formats do
      {output_file, output_format} =
        case output do
          "xml" -> {filename() <> "-cyclonedx-sbom.1.0.0.xml", "xml"}
          "json" -> {filename() <> "-cyclonedx-sbom.1.0.0.json", "json"}
          "spdxjson" -> {filename() <> "-spdx-sbom.1.0.0.spdx", "spdxjson"}
        end

      bin_path()
      |> System.cmd([
        "convert",
        "--input-file=" <> input_file,
        "--output-file=" <> output_directory() <> "/" <> output_file,
        "--output-version=v" <> version,
        "--output-format=" <> output_format
      ])

      output_directory() <> "/" <> output_file
    end
    |> print_filenames()
  end

  defp print_filenames(filenames) do
    Logger.debug("Created the following files ")

    Enum.with_index(filenames, fn name, index ->
      """
      #{index + 1}. #{Path.relative_to(name, File.cwd!())}
      """
    end)
    |> Mix.shell().info()
  end

  defp filename do
    to_string(name()) <> "." <> to_string(version())
  end

  defp name do
    config()[:app]
  end

  defp version do
    config()[:version]
  end

  defp config do
    Mix.Project.config()
  end

  defp output_directory do
    path = Application.get_env(:sbom, :bom_location) || "priv/static/.well-known/sbom"

    unless File.exists?(path) do
      File.mkdir_p!(path)
    end

    path
  end
end
