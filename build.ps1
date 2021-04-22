#!/usr/bin/env pwsh
#Requires -Version 7.0 -Modules @{ ModuleName='Pester'; ModuleVersion='5.2' }

<#
.SYNOPSIS
Build script for the module.

.PARAMETER Task
The task to run.

- Test, run unit tests
- Import, import the module in the current session (useful during development)
- Publish, publish the module to the gallery

.PARAMETER Module
The name of the module for which the script runs.
#>

[CmdletBinding(SupportsShouldProcess=$True)]

param (
  [ValidateSet('Test', 'Import', 'Publish')]
  [Parameter(Position = 0)]
  [string] $Task = 'Test',
  [string] $Module = 'Hospitable'
)

# Init
Set-StrictMode -version 'Latest'
$ErrorActionPreference = 'Stop'

# Switch task
switch ($Task) {
  'Test' {
    # Build Pester configuration
    $pesterConfiguration = @{
      Run = @{
        Path = (Join-Path $PSScriptRoot 'src')
      }
      CodeCoverage = @{
        Enabled = $true
      }
      Output = @{
        Verbosity = 'Detailed'
      }
    }

    # Run pester in a dedicated pwsh shell so it gets its own runspace
    # This is done this way because:
    # - running dedicated runspace directly with [PowerShell]::Create() makes it hard to get the streams properly rendered
    # - each time we change a class (e.g. while developing) we need a new runspace for the new definitions to be loaded
    # This is not free obviously but the overhead is worth it in my opinion...
    $encodedConfiguration = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([System.Management.Automation.PSSerializer]::Serialize($pesterConfiguration)))
    $command = @"
`$configuration = [PSCustomObject] [System.Management.Automation.PSSerializer]::Deserialize([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`'$encodedConfiguration`')));
Invoke-Pester -Configuration `$configuration
"@
    & pwsh -NoProfile -NoLogo -NonInteractive -WorkingDirectory $PSScriptRoot -Command "$command"
  }

  'Import' {
    Remove-Module -Name $Module -Force -ErrorAction 'SilentlyContinue'
    Import-Module -Name (Join-Path $PSScriptRoot "src/$($Module).psm1")
  }

  'Publish' {
    # Validate a NUGET_API_KEY environment variable was provided
    if (-Not (Test-Path env:NUGET_API_KEY)) {
      throw "`$env:NUGET_API_KEY is undefined (required to publish the module)"
    }

    # Prepare the module to publish (ignore what if preference)
    $releaseModuleFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()) $Module
    New-Item -ItemType Directory -Path $releaseModuleFolder -Force -WhatIf:$false | Out-Null
    Copy-Item `
      -Path (Join-Path $PSScriptRoot 'src' '*') `
      -Destination $releaseModuleFolder `
      -Exclude '*.Tests.ps1' `
      -Recurse `
      -WhatIf:$false

    # Publish the module
    Publish-Module `
      -Path $releaseModuleFolder `
      -Repository PSGallery `
      -NuGetApiKey $env:NUGET_API_KEY `
      -Verbose `
      -WhatIf:$WhatIfPreference
  }
}
