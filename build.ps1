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
        Exit = $true
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
    if (-Not $env:NUGET_API_KEY) {
      throw "`$env:NUGET_API_KEY is undefined (required to publish the module)"
    }

    # Prepare the module to publish (ignore what if preference)
    $releaseModuleFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()) $Module
    New-Item -ItemType Directory -Path $releaseModuleFolder -Force -WhatIf:$false | Out-Null
    Copy-Item `
      -Path (Join-Path $PSScriptRoot 'src' '*') `
      -Destination $releaseModuleFolder `
      -Exclude '*.Tests.ps1', 'TestHeader.Tests.ps1' `
      -Recurse `
      -WhatIf:$false

    #
    # Test the module in its publish folder
    #

    # Save current PSModulePath
    $originalModulePath = $env:PSModulePath
    try {
      # Instruct the test header to import Hospitable from the first installed location
      $env:HOSPITABLE_TEST_RELEASE = $true

      # Update PSModulePath so the published folder is the first location to look at
      $modulePaths = @()
      if ($originalModulePath) {
        $modulePaths = $originalModulePath.Split([IO.Path]::PathSeparator)
      }
      $modulePaths = @(Split-Path $releaseModuleFolder -Parent) + $modulePaths
      $env:PSModulePath = $modulePaths -Join [IO.Path]::PathSeparator

      # Test the module
      & (Join-Path $PSScriptRoot 'build.ps1') -Task 'Test'
    } finally {
      # Restore environment variables
      $env:HOSPITABLE_TEST_RELEASE = $null
      if ($originalModulePath) {
        $env:PSModulePath = $originalModulePath
      }
    }

    # Abort the publication if at least one test failed
    if ($LASTEXITCODE -ne 0) {
      throw "At least one test failed, aborting publication"
    }

    # Publish the module
    Publish-Module `
      -Path $releaseModuleFolder `
      -Repository 'PSGallery' `
      -NuGetApiKey $env:NUGET_API_KEY `
      -Verbose
  }
}
