defmodule Mix.Tasks.Sbom.Convert do
  @shortdoc "Convert bom file to different formats"

  use Mix.Task

  alias Sbom.Cli

  @default_path "bom.xml"

  @moduledoc """
  Generates a Software Bill-of-Materials (SBoM) in CycloneDX format.

  ## Options
    * `--input` (`-i`): the full path to the SBoM input file (default:
      #{@default_path})
  """

  @doc false
  @impl Mix.Task
  def run(all_args) do
    {opts, _args} = OptionParser.parse!( all_args, aliases: [i: :input], strict: [ input: :string ])
    input_path = opts[:input] || @default_path
    Cli.convert(input_path)
  end

end
