# IIS Versioned Deploy action

This action allows to deploy a website on IIS.

Deploy to IIS using PowerShell script to avoid downtime.

## Requirements

- A Windows runner

## Inputs

| Input | Required | Example | Default Value | Description |
|-|-|-|-|-|
| `website-name`     | Yes | `www.yourwebsite.ca` | | IIS website name |
| `source-path`      | Yes | `${{ github.workspace }}\website\publish` | | The path to the source directory that will be deployed |
| `destination-path` | Yes | `C:\inetpub\website-releases` | | The path to the site directory that will be deployed |
| `number-to-keep`   | No  | `4` | | Number of previous deployments to keep |

## How it works

This action deploys the website to a versioned directory inside the `destination-path`.
The directories are named using the pattern `r_<version>`, for example `r_1`, `r_2`, etc.

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

## Usage

<!-- start usage -->
```yaml
- uses: wallymathieu/iis-deploy@main
  with:
    website-name: 'MyWebsite'
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
    strategy:
      matrix:
        prod-tag: [prod-1, prod-2, prod-3]
    runs-on: [self-hosted, "${{ matrix.prod-tag }}"]
    steps:
      - uses: actions/checkout@v3
      # ... build steps ...
      - uses: wallymathieu/iis-deploy@main
        with:
          website-name: 'MyWebsite'
          source-path: '${{ github.workspace }}\website\publish'
          destination-path: 'C:\inetpub\website-releases'
```

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)

