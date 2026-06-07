# IIS Versioned Deploy

Deploy a website (and optionally a virtual application within it) to IIS with
reduced downtime by switching the site's physical path to a freshly copied,
versioned release folder.

This extension adds the **IIS Versioned App Deployment** task to your Azure
Pipelines so you can release ASP.NET / IIS sites without leaving the published
files locked or serving a half-copied directory.

## Requirements

- A **self-hosted Windows agent** on the target machine.
- IIS installed with the PowerShell `WebAdministration` module available.
- An existing IIS website (and virtual application, if you deploy one).

## How it works

The task copies your published output into a new versioned directory inside the
destination path and then repoints IIS at it. The directories are named using
the pattern `r_<version>`, for example `r_1`, `r_2`, etc.

When a new deployment runs:

1. A new directory is created (e.g. `r_5`).
2. The site content is copied into this new directory.
3. The IIS website (or virtual application) physical path is updated to point to
   the new directory.
4. Old directories are cleaned up, keeping only the number specified in
   **Number of releases to keep**.

Example structure in `C:\inetpub\website-releases`:

```
r_3
r_4
r_5  <-- IIS points here
```

Because IIS is only switched to the new folder once the copy has completed,
downtime is minimal and rollbacks are as simple as repointing to a previous
`r_<version>` directory.

## Inputs

| Input | Required | Description |
|-|-|-|
| `WebSiteName`     | Yes | Name of an existing IIS website on the target machine |
| `AppName`         | No  | Optional IIS virtual application name within the site. Leave empty to deploy the site root |
| `SourcePath`      | Yes | Path to the source directory that will be deployed |
| `DestinationPath` | Yes | Parent directory where versioned release folders are created |
| `NumberToKeep`    | No  | Number of previous deployments to retain (default `4`) |

## Usage

Add the task to a pipeline that runs on a self-hosted Windows agent:

```yaml
- task: IISVersionedAppDeployment@0
  inputs:
    WebSiteName: 'MyWebsite'
    AppName: 'virtual_app'        # optional
    SourcePath: '$(System.DefaultWorkingDirectory)/website/publish'
    DestinationPath: 'C:\inetpub\website-releases'
    NumberToKeep: 2
```

The task runs on the Node 20 handler and shells out to a PowerShell deployment
script, so the agent must have IIS and the `WebAdministration` module available.

## Support

This extension is open source. Source code, issue tracking, and additional
documentation (including AppCmd operational guidance) are available on
[GitHub](https://github.com/wallymathieu/iis-deploy).

## License

Released under the [MIT License](https://github.com/wallymathieu/iis-deploy/blob/main/LICENSE).
