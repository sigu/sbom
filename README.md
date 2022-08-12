# SBoM

Generates a Software Bill-of-Materials (SBoM) for Mix projects, in [CycloneDX](https://cyclonedx.org)
format.

Full documentation can be found at [https://hexdocs.pm/sbom](https://hexdocs.pm/sbom).

For a quick demo of how this might be used, check out [this blog post](https://blog.voltone.net/post/24).

## Installation

To install the Mix task globally on your system, run `mix archive.install hex sbom`.

Alternatively, the package can be added to a project's dependencies to make the
Mix task available for that project only:

```elixir
def deps do
  [
    {:sbom, git: "https://github.com/sigu/sbom.git", branch: "auto-install-bom", only: :dev, runtime: false}
  ]
end
```

## Usage

To produce a CycloneDX SBoM, run `mix sbom.cyclonedx` from the project
directory. The result is written to a file named `bom.xml`, unless a different
name is specified using the `-o` option.

By default only the dependencies used in production are included. To include all
dependencies, including those for the 'dev' and 'test' environments, pass the
`-d` command line option: `mix sbom.cyclonedx -d`.

*Note that MIX_ENV does not affect which dependencies are included in the
output; the task should normally be run in the default (dev) environment*

For more information on the command line arguments accepted by the Mix task
run `mix help sbom.cyclonedx`.

## NPM packages and other dependencies

If you are running a phoenix project, you can generate your phoenix dependencies sbom file too by running the command `mix sbom.phx`. You need to add the following to your dev config

``` elixir
config :sbom,
  cyclone_cli: "0.24.0",
  cyclone_npm: "3.10.4",
  cd: Path.expand("../assets", __DIR__),
  bom_location: Path.expand("../priv/static/.well-known/sbom", __DIR__)
```

### Automated generating of sbom

This tool only considers Hex, GitHub and BitBucket dependencies managed through
Mix. To build a comprehensive SBoM of a deployment, including NPM and/or
operating system packages, it may be necessary to merge multiple CycloneDX files
into one.

The [@cyclonedx/bom](https://www.npmjs.com/package/@cyclonedx/bom) tool on NPM
can not only generate an SBoM for your JavaScript assets, but it can also merge
in the output of the 'sbom.cyclonedx' Mix task and other scanners, through the
'-a' option, producing a single CycloneDX XML file.


## To do

- [ ] enable passing of arguments to the cli
- [ ] configurable output filenames
- [ ] generate templates and serve the sbom on phoenix projects
