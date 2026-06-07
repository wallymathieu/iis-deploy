#Requires -Modules Pester

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    Import-Module "$here\IisDeploy.psm1" -Force

    function New-TempDir {
        New-Item -Type Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString()))
    }

    # The Move-Site function relies on the WebAdministration cmdlets which are
    # only available on Windows with IIS installed. Provide global stubs so the
    # functions can be resolved (and therefore mocked) on any platform.
    function global:Get-Website { [CmdletBinding()] param([string]$Name) }
    function global:Get-WebApplication { [CmdletBinding()] param([string]$Site, [string]$Name) }
}

AfterAll {
    Remove-Item function:global:Get-Website -ErrorAction SilentlyContinue
    Remove-Item function:global:Get-WebApplication -ErrorAction SilentlyContinue
}

Describe 'Get-NextFolderName' {
    It 'should return r_1 for empty directory' {
        $tempDir = New-TempDir
        try {
            $nextFolder = Get-NextFolderName -targetFolder $tempDir.FullName
            $nextFolder | Should -Be 'r_1'
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }

    It 'should return next version number' {
        $tempDir = New-TempDir
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

    It 'should ignore directories and files that do not match the release pattern' {
        $tempDir = New-TempDir
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'r_5') | Out-Null
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'backup') | Out-Null
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'r_old') | Out-Null
        New-Item -Type File -Path (Join-Path $tempDir.FullName 'r_99') | Out-Null
        try {
            $nextFolder = Get-NextFolderName -targetFolder $tempDir.FullName
            $nextFolder | Should -Be 'r_6'
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }
}

Describe 'Deploy-Files' {
    It 'should create the destination directory and copy files' {
        $sourceDir = New-TempDir
        $destParent = New-TempDir
        $destinationDir = Join-Path $destParent.FullName 'r_1'
        Set-Content -Path (Join-Path $sourceDir.FullName 'index.html') -Value '<html></html>'
        try {
            Deploy-Files -sourceDir $sourceDir.FullName -destinationDir $destinationDir
            Test-Path $destinationDir | Should -Be $true
            Test-Path (Join-Path $destinationDir 'index.html') | Should -Be $true
        }
        finally {
            Remove-Item -Path $sourceDir.FullName -Recurse -Force
            Remove-Item -Path $destParent.FullName -Recurse -Force
        }
    }

    It 'should copy nested directories recursively' {
        $sourceDir = New-TempDir
        $destParent = New-TempDir
        $destinationDir = Join-Path $destParent.FullName 'r_1'
        $nested = New-Item -Type Directory -Path (Join-Path $sourceDir.FullName 'assets')
        Set-Content -Path (Join-Path $nested.FullName 'app.js') -Value 'console.log(1)'
        try {
            Deploy-Files -sourceDir $sourceDir.FullName -destinationDir $destinationDir
            Test-Path (Join-Path $destinationDir 'assets/app.js') | Should -Be $true
        }
        finally {
            Remove-Item -Path $sourceDir.FullName -Recurse -Force
            Remove-Item -Path $destParent.FullName -Recurse -Force
        }
    }
}

Describe 'Move-Site' {
    It 'should update the website physical path when the site exists' {
        Mock -ModuleName IisDeploy Import-Module {}
        Mock -ModuleName IisDeploy Get-Website { [pscustomobject]@{ Name = 'MySite' } }
        Mock -ModuleName IisDeploy Set-ItemProperty {}

        Move-Site -siteName 'MySite' -newPath 'C:\releases\r_1'

        Should -Invoke -ModuleName IisDeploy Get-Website -Times 1
        Should -Invoke -ModuleName IisDeploy Set-ItemProperty -Times 1 -ParameterFilter {
            $Path -eq 'IIS:\Sites\MySite' -and $Name -eq 'physicalPath' -and $Value -eq 'C:\releases\r_1'
        }
    }

    It 'should update the virtual application path when appName is provided' {
        Mock -ModuleName IisDeploy Import-Module {}
        Mock -ModuleName IisDeploy Get-WebApplication { [pscustomobject]@{ Path = '/app' } }
        Mock -ModuleName IisDeploy Set-ItemProperty {}

        Move-Site -siteName 'MySite' -appName 'app' -newPath 'C:\releases\r_2'

        Should -Invoke -ModuleName IisDeploy Get-WebApplication -Times 1 -ParameterFilter {
            $Site -eq 'MySite' -and $Name -eq 'app'
        }
        Should -Invoke -ModuleName IisDeploy Set-ItemProperty -Times 1 -ParameterFilter {
            $Path -eq 'IIS:\Sites\MySite\app' -and $Value -eq 'C:\releases\r_2'
        }
    }

    It 'should throw when the site is not found' {
        Mock -ModuleName IisDeploy Import-Module {}
        Mock -ModuleName IisDeploy Get-Website { $null }
        Mock -ModuleName IisDeploy Set-ItemProperty {}

        { Move-Site -siteName 'Missing' -newPath 'C:\releases\r_1' } | Should -Throw "*not found in IIS*"
        Should -Invoke -ModuleName IisDeploy Set-ItemProperty -Times 0
    }
}

Describe 'Cleanup-OldDirectories' {
    It 'should keep the specified number of directories' {
        $tempDir = New-TempDir
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

    It 'should not remove anything when the count is within the limit' {
        $tempDir = New-TempDir
        1..2 | ForEach-Object {
            New-Item -Type Directory -Path (Join-Path $tempDir.FullName "r_$_") | Out-Null
        }
        try {
            Cleanup-OldDirectories -targetFolder $tempDir.FullName -keep 4
            $remaining = Get-ChildItem -Path $tempDir.FullName -Directory
            $remaining.Count | Should -Be 2
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }

    It 'should ignore directories that do not match the release pattern' {
        $tempDir = New-TempDir
        1..5 | ForEach-Object {
            New-Item -Type Directory -Path (Join-Path $tempDir.FullName "r_$_") | Out-Null
        }
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'logs') | Out-Null
        try {
            Cleanup-OldDirectories -targetFolder $tempDir.FullName -keep 2
            $remaining = Get-ChildItem -Path $tempDir.FullName -Directory
            ($remaining.Name -contains 'logs') | Should -Be $true
            ($remaining.Name -contains 'r_4') | Should -Be $true
            ($remaining.Name -contains 'r_5') | Should -Be $true
            ($remaining.Name -contains 'r_1') | Should -Be $false
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }

    It 'should skip release folders that are reparse points' {
        $tempDir = New-TempDir
        $realTarget = New-TempDir
        1..3 | ForEach-Object {
            New-Item -Type Directory -Path (Join-Path $tempDir.FullName "r_$_") | Out-Null
        }
        New-Item -ItemType SymbolicLink -Path (Join-Path $tempDir.FullName 'r_4') -Target $realTarget.FullName | Out-Null
        try {
            Cleanup-OldDirectories -targetFolder $tempDir.FullName -keep 1 -WarningAction SilentlyContinue
            $remaining = Get-ChildItem -Path $tempDir.FullName -Directory
            # The symlink (r_4) is never removed, and only one real folder is kept.
            ($remaining.Name -contains 'r_4') | Should -Be $true
            ($remaining.Name -contains 'r_3') | Should -Be $true
            ($remaining.Name -contains 'r_2') | Should -Be $false
            ($remaining.Name -contains 'r_1') | Should -Be $false
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
            Remove-Item -Path $realTarget.FullName -Recurse -Force
        }
    }

    It 'should throw when keep is less than 1' {
        $tempDir = New-TempDir
        New-Item -Type Directory -Path (Join-Path $tempDir.FullName 'r_1') | Out-Null
        try {
            { Cleanup-OldDirectories -targetFolder $tempDir.FullName -keep 0 } | Should -Throw '*at least 1*'
        }
        finally {
            Remove-Item -Path $tempDir.FullName -Recurse -Force
        }
    }
}
