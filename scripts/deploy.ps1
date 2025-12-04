#Requires -Modules WebAdministration

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$from,

    [Parameter(Mandatory=$true)]
    [string]$path,

    [Parameter(Mandatory=$true)]
    [string]$sitename
)

# Import the module from the same directory
$modulePath = Join-Path $PSScriptRoot "IisDeploy.psm1"
Import-Module $modulePath -Force

try {
    Write-Host "Starting deployment for site '$sitename'"
    
    $nextFolderName = Get-NextFolderName -targetFolder $path
    $newReleaseDir = Join-Path $path $nextFolderName
    
    Deploy-Files -sourceDir $from -destinationDir $newReleaseDir
    
    Move-Site -siteName $sitename -newPath $newReleaseDir
    
    Cleanup-OldDirectories -targetFolder $path
    
    Write-Host "Deployment completed successfully."
}
catch {
    Write-Error "An error occurred during deployment: $_"
    exit 1
}

