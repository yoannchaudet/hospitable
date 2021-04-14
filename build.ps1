#!/usr/bin/env pwsh
#Requires -Version 7.0 -Modules @{ ModuleName='Pester'; ModuleVersion='5.2.0-alpha3' }

<#
.SYNOPSIS
Build script for the module.

.PARAMETER Task
The task to run.

- Test, run unit tests
- Import, import the module in the current session (useful during development)

.PARAMETER Module
The name of the module for which the script runs.
#>

param (
  [ValidateSet('Test', 'Import')]
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
    & pwsh -NoProfile -NoLogo -NonInteractive -Command "$command"
  }

  'Import' {
    Remove-Module -Name $Module -Force -ErrorAction 'SilentlyContinue'
    Import-Module -Name (Join-Path $PSScriptRoot "src/$($Module).psm1")
  }
}
