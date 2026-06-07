#Requires -Modules WebAdministration

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$sourceDir,

    [Parameter(Mandatory=$true)]
    [string]$siteName,

    [Parameter(Mandatory=$false)]
    [string]$appName = "",

    [Parameter(Mandatory=$false)]
    [string]$releaseParentDir,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$keep = 4
)

# Import the module from the same directory
$modulePath = Join-Path $PSScriptRoot "IisDeploy.psm1"
Import-Module $modulePath -Force

try {
    Write-Host "Starting deployment for site '$siteName'"
    
    if ([string]::IsNullOrWhiteSpace($releaseParentDir)) {
        $currentPath = Get-SitePhysicalPath -siteName $siteName -appName $appName
        $releaseParentDir = Split-Path -Parent $currentPath
        Write-Host "No releaseParentDir provided. Using parent of current site path: '$releaseParentDir'"
    }
    
    $nextFolderName = Get-NextFolderName -targetFolder $releaseParentDir
    $newReleaseDir = Join-Path $releaseParentDir $nextFolderName
    
    Deploy-Files -sourceDir $sourceDir -destinationDir $newReleaseDir
    
    Move-Site -siteName $siteName -appName $appName -newPath $newReleaseDir
    
    Cleanup-OldDirectories -targetFolder $releaseParentDir -keep $keep
    
    Write-Host "Deployment completed successfully."
}
catch {
    Write-Error "An error occurred during deployment: $_"
    exit 1
}
