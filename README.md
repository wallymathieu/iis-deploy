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

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)

