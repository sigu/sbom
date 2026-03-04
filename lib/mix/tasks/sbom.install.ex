defmodule Mix.Tasks.Sbom.Install do
  @shortdoc "Install Elixir Sbom"

  use Mix.Task

  def run(_args) do
    if function_exported?(Mix, :ensure_application!, 1) do
      Mix.ensure_application!(:inets)
    end

    Sbom.Cli.install()
  end
end
