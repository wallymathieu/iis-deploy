#Requires -Modules WebAdministration
#Requires -RunAsAdministrator

function Add-HostsEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ip,
        [Parameter(Mandatory=$true)]
        [string]$hostname,
        [string]$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    )
    $content = Get-Content $hostsFile
    
    # Regex to find hostname, ignoring comments
    $found = $content | ForEach-Object {
        $line = $_.Split('#')[0] # Get content before any comment
        if ($line -match "\s$([regex]::Escape($hostname))(\s|$)") {
            return $true
        }
    } | Select-Object -First 1

    if (-not $found) {
        Write-Host "Adding hosts file entry for $hostname"
        $entry = "`n{0}`t{1}" -f $ip, $hostname
        try {
            Add-Content -Path $hostsFile -Value $entry -ErrorAction Stop
            Write-Host "Successfully added hosts file entry."
        }
        catch {
            Write-Error "Failed to write to hosts file. Please ensure you are running this script with Administrator privileges."
            throw
        }
    } else {
        Write-Host "Hosts file entry for $hostname already exists."
    }
}

function New-IISSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$siteName,
        [Parameter(Mandatory=$true)]
        [string]$hostName,
        [Parameter(Mandatory=$true)]
        [string]$physicalPath
    )
    Import-Module WebAdministration -ErrorAction Stop

    if (Test-Path "IIS:\Sites\$siteName") {
        Write-Host "Site '$siteName' already exists."
        return
    }

    Write-Host "Creating new IIS site '$siteName'"

    # Create Application Pool
    $appPoolName = $siteName
    if (-not (Test-Path "IIS:\AppPools\$appPoolName")) {
        Write-Host "Creating application pool '$appPoolName'"
        New-WebAppPool -Name $appPoolName
        Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value "v4.0"
    }

    # Create Website
    Write-Host "Creating website '$siteName' at path '$physicalPath'"
    $site = New-Website -Name $siteName -PhysicalPath $physicalPath -ApplicationPool $appPoolName -HostHeader $hostName
    
    # Configure site
    Set-ItemProperty -Path "IIS:\Sites\$siteName" -Name "serverAutoStart" -Value $true
    
    Write-Host "Site '$siteName' created successfully."
}

Export-ModuleMember -Function Add-HostsEntry, New-IISSite
