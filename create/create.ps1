<#
.SYNOPSIS
    Creates and configures an IIS website, application pool, and adds a hosts file entry.
    This script must be run with Administrator privileges to modify the hosts file and IIS configuration.
.DESCRIPTION
    This PowerShell script performs the initial setup for a new website in IIS. It takes the physical path for the site content, a hostname, and a site name as input.

    The script will:
    1. Check if an entry for the specified hostname exists in the local hosts file. If not, it adds an entry pointing to 127.0.0.1.
    2. Check if a website with the specified name already exists in IIS.
    3. If the site does not exist, it will:
        a. Create a new application pool with the same name as the site, configured for .NET v4.0.
        b. Create a new website with a binding for the specified hostname on port 80.
        c. Assign the new application pool to the website.
        d. Configure the website to start automatically.
.PARAMETER path
    The physical path to the root directory of the website content.
.PARAMETER hostname
    The hostname that will be used for the site binding (e.g., my.website.local).
.PARAMETER sitename
    The name for the new website in IIS.
.EXAMPLE
    .\create.ps1 -path "C:\inetpub\wwwroot\mysite" -hostname "dev.mysite.com" -sitename "MyDevSite"

    This example creates a new IIS site named "MyDevSite" with content from "C:\inetpub\wwwroot\mysite". It will be accessible via "http://dev.mysite.com", and a corresponding entry will be added to the hosts file if it doesn't exist.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$path,

    [Parameter(Mandatory=$true)]
    [string]$hostname,

    [Parameter(Mandatory=$true)]
    [string]$sitename
)

#Requires -Modules WebAdministration
#Requires -RunAsAdministrator

# Import the module from the same directory
$modulePath = Join-Path $PSScriptRoot "IisCreate.psm1"
Import-Module $modulePath -Force

try {
    Write-Host "Starting site creation process for '$sitename'"
    
    # Ensure physical path exists
    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Host "Website content directory not found. Creating directory: $path"
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }

    Add-HostsEntry -ip "127.0.0.1" -hostname $hostname
    
    New-IISSite -siteName $sitename -hostName $hostname -physicalPath $path
    
    Write-Host "Site creation process completed successfully."
}
catch {
    Write-Error "An error occurred during site creation: $_"
    exit 1
}

