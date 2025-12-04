#Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$here\IisDeploy.psm1" -Force

Describe 'Get-NextFolderName' {
    It 'should return r_1 for empty directory' {
        $tempDir = New-Item -Type Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
        try {
            $nextFolder = Get-NextFolderName -targetFolder $tempDir.FullName
            $nextFolder | Should -Be 'r_1'
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }

    It 'should return next version number' {
        $tempDir = New-Item -Type Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'r_1') | Out-Null
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'r_2') | Out-Null
        try {
            $nextFolder = Get-NextFolderName -targetFolder $tempDir.FullName
            $nextFolder | Should -Be 'r_3'
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }
}

Describe 'Cleanup-OldDirectories' {
    It 'should keep the specified number of directories' {
        $tempDir = New-Item -Type Directory -Path (Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString()))
        1..5 | ForEach-Object {
            New-Item -Type Directory -Path (Join-Path $tempDir.FullName "r_$_") | Out-Null
        }
        try {
            Cleanup-OldDirectories -targetFolder $tempDir.FullName -keep 2
            $remaining = Get-ChildItem -Path $tempDir.FullName -Directory
            $remaining.Count | Should -Be 2
            ($remaining.Name -contains 'r_4') | Should -Be $true
            ($remaining.Name -contains 'r_5') | Should -Be $true
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }
}
