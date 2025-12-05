#Requires -Modules WebAdministration

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$sourceDir,

    [Parameter(Mandatory=$true)]
    [string]$siteName,

    [Parameter(Mandatory=$true)]
    [string]$releaseParentDir,

    [Parameter(Mandatory=$false)]
    [int]$keep = 4
)

# Import the module from the same directory
$modulePath = Join-Path $PSScriptRoot "IisDeploy.psm1"
Import-Module $modulePath -Force

try {
    Write-Host "Starting deployment for site '$siteName'"
    
    $nextFolderName = Get-NextFolderName -targetFolder $releaseParentDir
    $newReleaseDir = Join-Path $releaseParentDir $nextFolderName
    
    Deploy-Files -sourceDir $sourceDir -destinationDir $newReleaseDir
    
    Move-Site -siteName $siteName -newPath $newReleaseDir
    
    Cleanup-OldDirectories -targetFolder $releaseParentDir -keep $keep
    
    Write-Host "Deployment completed successfully."
}
catch {
    Write-Error "An error occurred during deployment: $_"
    exit 1
}

