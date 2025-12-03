#Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$here\IisCreate.psm1" -Force

Describe 'Add-HostsEntry' {
    $tempHostsFile = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString() + ".txt")

    AfterEach {
        if (Test-Path $tempHostsFile) {
            Remove-Item $tempHostsFile -Force
        }
    }

    It 'should add a new entry if it does not exist' {
        Set-Content -Path $tempHostsFile -Value "127.0.0.1`tlocalhost"
        Add-HostsEntry -ip "127.0.0.1" -hostname "test.local" -hostsFile $tempHostsFile
        $content = Get-Content $tempHostsFile
        $content -match "127.0.0.1`ttest.local" | Should -Not -BeNull
    }

    It 'should not add an entry if it already exists' {
        $initialContent = "127.0.0.1`tlocalhost`n127.0.0.1`ttest.local"
        Set-Content -Path $tempHostsFile -Value $initialContent
        Add-HostsEntry -ip "127.0.0.1" -hostname "test.local" -hostsFile $tempHostsFile
        $content = Get-Content $tempHostsFile -Raw
        $content | Should -Be $initialContent
    }

    It 'should add an entry if the existing one is commented out' {
        Set-Content -Path $tempHostsFile -Value "# 127.0.0.1`ttest.local"
        Add-HostsEntry -ip "127.0.0.1" -hostname "test.local" -hostsFile $tempHostsFile
        $content = Get-Content $tempHostsFile
        $content -match "^127.0.0.1`ttest.local" | Should -Not -BeNull
    }

    It 'should ignore inline comments when checking for existing entries' {
        $initialContent = "127.0.0.1`ttest.local # some comment"
        Set-Content -Path $tempHostsFile -Value $initialContent
        Add-HostsEntry -ip "127.0.0.1" -hostname "test.local" -hostsFile $tempHostsFile
        $content = Get-Content $tempHostsFile -Raw
        $content | Should -Be $initialContent
    }
}
