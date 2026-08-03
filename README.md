# IIS Versioned Deploy

Deploy a website on IIS (including virtual applications within a site) as a
GitHub Action or an Azure DevOps pipeline task.

Deploy to IIS using PowerShell script to avoid downtime.

You can find it on [Azure Devops as iis-versioned-deploy](https://marketplace.visualstudio.com/items?itemName=wallymathieu.iis-versioned-deploy)

## Requirements

- A Windows runner on the target machine.
- IIS installed with the PowerShell `WebAdministration` module available.
- An existing IIS website (and virtual application, if you deploy one).

## Inputs

| Input | Required | Example | Default Value | Description |
|-|-|-|-|-|
| `website-name`     | No  | `www.yourwebsite.ca` | | IIS website name (preferred). Required if `site-name` is not provided. |
| `site-name`        | No  | `www.yourwebsite.ca` | | Deprecated alias for `website-name`. Required if `website-name` is not provided. |
| `app-name`         | No  | `virt-app` | | IIS website virtual application name | 
| `source-path`      | Yes | `${{ github.workspace }}\website\publish` | | The path to the source directory that will be deployed |
| `destination-path` | No  | `C:\inetpub\website-releases` | | The parent path where versioned release folders are created. Defaults to the parent folder of the current site directory. |
| `release-prefix`   | No  | `r_` | `r_` | Prefix used for the versioned release folders |
| `number-to-keep`   | No  | `4` | `4` | Total number of release folders to retain, including the current deployment |

## How it works

This action deploys the website to a versioned directory inside the `destination-path`.
The directories are named using the pattern `<release-prefix><version>`, for example
`r_1`, `r_2`, etc. The prefix defaults to `r_` and can be changed with the
`release-prefix` input.

If `destination-path` is omitted, the parent folder of the site's current physical
path is used as the destination, so existing versioned folders next to it are reused.

When a new deployment runs:
1. A new directory is created (e.g. `r_5`).
2. The site content is copied to this new directory.
3. The IIS website physical path is updated to point to this new directory.
4. Old directories are cleaned up, keeping only the number specified in `number-to-keep`.

Example structure in `C:\inetpub\website-releases`:
```
r_3
r_4
r_5  <-- IIS points here
```

## AppCmd insights

See [AppCmd operational guidance](docs/appcmd-operational-guidance.md).

## Usage

<!-- start usage -->
```yaml
- uses: wallymathieu/iis-deploy@af23a6d2f13062a20d60196ada2528a400e829ca
  with:
    website-name: 'MyWebsite'
    app-name: 'virtual_app'
    source-path: '${{ github.workspace }}\website\publish'
    destination-path: 'C:\inetpub\website-releases'
    number-to-keep: 2
```
<!-- end usage -->

## Deploying on multiple runners

If you need to deploy to multiple servers, you can use the matrix strategy with runner tags.
This allows you to run the deployment job on multiple runners.

```yaml
jobs:
  deploy:
    permissions:
      contents: none
    needs: build
    strategy:
      matrix:
        prod-tag: [prod-1, prod-2, prod-3]
    runs-on: [self-hosted, "${{ matrix.prod-tag }}"]
    steps:
      - name: Download artifact from build job
        uses: actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093
        with:
          name: .net-app
          path: website\publish
      - uses: wallymathieu/iis-deploy@af23a6d2f13062a20d60196ada2528a400e829ca
        with:
          website-name: 'MyWebsite'
          source-path: '${{ github.workspace }}\website\publish'
          destination-path: 'C:\inetpub\website-releases'
```

## Azure DevOps task

This repository also ships the same deployment logic as an Azure DevOps pipeline
task (`buildandreleasetask/`), packaged as an extension via `vss-extension.json`.

### Inputs

| Input | Required | Description |
|-|-|-|
| `WebSiteName`     | Yes | Name of an existing IIS website on the target machine |
| `AppName`         | No  | Optional IIS virtual application name within the site |
| `SourcePath`      | Yes | Path to the source directory that will be deployed |
| `DestinationPath` | No  | Parent directory where versioned release folders are created. Defaults to the parent folder of the current site directory. |
| `ReleasePrefix`   | No  | Prefix used for the versioned release folders (default `r_`) |
| `NumberToKeep`    | No  | Total number of release folders to retain, including the current deployment (default `4`) |

Example YAML usage once the extension is installed in your organization:

```yaml
- task: IISVersionedAppDeployment@0
  inputs:
    WebSiteName: 'MyWebsite'
    AppName: 'virtual_app'        # optional
    SourcePath: '$(System.DefaultWorkingDirectory)/website/publish'
    DestinationPath: 'C:\inetpub\website-releases'
    NumberToKeep: 2
```

The task runs on the Node 20 handler and shells out to the same `deploy.ps1`
PowerShell script, so it requires a **self-hosted Windows agent** with IIS and
the `WebAdministration` module available.

### Building and packaging

```bash
cd buildandreleasetask
npm install
npm run build        # compiles index.ts and copies the PowerShell scripts
npm test             # runs the task validation tests
npm prune --omit=dev # keep only runtime deps for packaging

# From the repository root:
npx tfx-cli extension create --manifest-globs vss-extension.json
```

This produces a `.vsix` you can upload to the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/manage) and
install into your Azure DevOps organization. If packaging a fork, replace the
`publisher` in `vss-extension.json` with your own
[publisher ID](https://learn.microsoft.com/azure/devops/extend/publish/overview).

The Pester tests for the PowerShell deployment logic can be run with:

```powershell
Invoke-Pester ./scripts/deploy.tests.ps1
```

## Alternatives

- [ChristopheLav/iis-deploy](https://github.com/ChristopheLav/iis-deploy) – another GitHub Action for IIS deployment
- [Octopus Deploy](https://octopus.com/) – a dedicated deployment automation tool with IIS support
- [Azure DevOps Pipelines](https://azure.microsoft.com/en-us/products/devops/pipelines) connected to your GitHub repository

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)
