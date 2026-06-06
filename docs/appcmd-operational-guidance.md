# AppCmd operational guidance

This action updates IIS through the `WebAdministration` PowerShell module (`Set-ItemProperty` on `IIS:\Sites\...`).
If you prefer to inspect the same state with `AppCmd.exe`, see Microsoft docs:
https://learn.microsoft.com/en-us/iis/get-started/getting-started-with-iis/getting-started-with-appcmdexe

Common checks on the runner:

```powershell
# List configured sites
& "$env:windir\System32\inetsrv\appcmd.exe" list site

# Read the physical path for a site
& "$env:windir\System32\inetsrv\appcmd.exe" list site "MyWebsite" /text:physicalPath
```
