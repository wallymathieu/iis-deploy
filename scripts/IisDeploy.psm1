function Get-NextFolderName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$targetFolder,
        [Parameter(Mandatory=$false)]
        [string]$releasePrefix = 'r_'
    )
    $escapedPrefix = [regex]::Escape($releasePrefix)
    $releaseDirs = Get-ChildItem -Path $targetFolder -Directory | Where-Object { $_.Name -match "^$escapedPrefix\d+$" }
    if (-not $releaseDirs) {
        $latestVersion = 0
    } else {
        $latestVersion = $releaseDirs | ForEach-Object { [int]($_.Name -replace "^$escapedPrefix", '') } | Measure-Object -Maximum | ForEach-Object { $_.Maximum }
    }
    $newVersion = $latestVersion + 1
    return "$releasePrefix$newVersion"
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

function Get-SitePhysicalPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$siteName,
        [Parameter(Mandatory=$false)]
        [string]$appName = ""
    )
    Import-Module WebAdministration -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace($appName)) {
        $siteItem = "$siteName\$appName"
        $sitePath = "IIS:\Sites\$siteName\$appName"
        $site = Get-WebApplication -Site $siteName -Name $appName -ErrorAction SilentlyContinue
    } else {
        $siteItem = "$siteName"
        $sitePath = "IIS:\Sites\$siteName"
        $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
    }

    if (-not $site) {
        throw "Site '$siteItem' not found in IIS."
    }

    $physicalPath = (Get-ItemProperty -Path $sitePath -Name physicalPath -ErrorAction SilentlyContinue).physicalPath
    if ([string]::IsNullOrWhiteSpace($physicalPath)) {
        throw "Could not determine the current physical path for site '$siteItem'."
    }
    return $physicalPath
}

function Move-Site {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$siteName,
        [Parameter(Mandatory=$false)]
        [string]$appName = "",
        [Parameter(Mandatory=$true)]
        [string]$newPath
    )
    Import-Module WebAdministration -ErrorAction Stop
    if (-not [string]::IsNullOrWhiteSpace($appName)) {
        $siteItem = "$siteName\$appName"
        $sitePath = "IIS:\Sites\$siteName\$appName"
        $site = Get-WebApplication -Site $siteName -Name $appName -ErrorAction SilentlyContinue
    } else {
        $siteItem = "$siteName"
        $sitePath = "IIS:\Sites\$siteName"
        $site = Get-Website -Name $siteName -ErrorAction SilentlyContinue
    }

    if ($site) {
        Write-Host "Updating physical path for site '$siteItem' to '$newPath'"
        Set-ItemProperty -Path $sitePath -Name physicalPath -Value $newPath
        Write-Host "Site path updated successfully."
    } else {
        Write-Error "Site '$siteItem' not found in IIS."
        throw "Site '$siteItem' not found in IIS."
    }
}

function Cleanup-OldDirectories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$targetFolder,
        [int]$keep = 4,
        [Parameter(Mandatory=$false)]
        [string]$releasePrefix = 'r_'
    )
    if ($keep -lt 1) {
        throw "keep must be at least 1."
    }

    $escapedPrefix = [regex]::Escape($releasePrefix)
    $allReleaseDirs = Get-ChildItem -Path $targetFolder -Directory | Where-Object { $_.Name -match "^$escapedPrefix\d+$" }
    $unsafeReleaseDirs = $allReleaseDirs | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }
    foreach ($unsafeDir in $unsafeReleaseDirs) {
        Write-Warning "Skipping release folder '$($unsafeDir.FullName)' because it is a reparse point."
    }

    $releaseDirs = $allReleaseDirs |
        Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) } |
        Sort-Object -Property @{Expression = {[int]($_.Name -replace "^$escapedPrefix",'')} } -Descending
    
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

Export-ModuleMember -Function Get-NextFolderName, Deploy-Files, Get-SitePhysicalPath, Move-Site, Cleanup-OldDirectories