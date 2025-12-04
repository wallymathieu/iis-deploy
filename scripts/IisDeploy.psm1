#Requires -Modules WebAdministration

function Get-NextFolderName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$targetFolder
    )
    $releaseDirs = Get-ChildItem -Path $targetFolder -Directory | Where-Object { $_.Name -match '^r_\d+$' }
    if (-not $releaseDirs) {
        $latestVersion = 0
    } else {
        $latestVersion = $releaseDirs | ForEach-Object { [int]($_.Name -replace 'r_', '') } | Measure-Object -Maximum | ForEach-Object { $_.Maximum }
    }
    $newVersion = $latestVersion + 1
    return "r_$newVersion"
}

function Deploy-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$sourceDir,
        [Parameter(Mandatory=$true)]
        [string]$destinationDir
    )
    Write-Host "Creating directory $destinationDir"
    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    Write-Host "Copying files from $sourceDir to $destinationDir"
    Copy-Item -Path (Join-Path $sourceDir '*') -Destination $destinationDir -Recurse -Force
}

function Move-Site {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$siteName,
        [Parameter(Mandatory=$true)]
        [string]$newPath
    )
    Import-Module WebAdministration -ErrorAction Stop
    $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
    if ($site) {
        Write-Host "Updating physical path for site '$siteName' to '$newPath'"
        Set-ItemProperty -Path "IIS:\Sites\$siteName" -Name physicalPath -Value $newPath
        Write-Host "Site path updated successfully."
    } else {
        Write-Error "Site '$siteName' not found in IIS."
        throw "Site '$siteName' not found in IIS."
    }
}

function Cleanup-OldDirectories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$targetFolder,
        [int]$keep = 4
    )
    $releaseDirs = Get-ChildItem -Path $targetFolder -Directory | Where-Object { $_.Name -match '^r_\d+$' } | Sort-Object -Property @{Expression = {[int]($_.Name -replace 'r_','')} } -Descending
    
    if ($releaseDirs.Count -gt $keep) {
        $dirsToRemove = $releaseDirs | Select-Object -Skip $keep
        foreach ($dir in $dirsToRemove) {
            Write-Host "Removing old directory: $($dir.FullName)"
            Remove-Item -Path $dir.FullName -Recurse -Force
        }
    } else {
        Write-Host "No old directories to clean up."
    }
}

Export-ModuleMember -Function Get-NextFolderName, Deploy-Files, Move-Site, Cleanup-OldDirectories