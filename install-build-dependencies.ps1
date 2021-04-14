#!/usr/bin/env pwsh
#Requires -Version 7.0

# Init
Set-StrictMode -version 'Latest'
$ErrorActionPreference = 'Stop'

# Parse the build script
$buildScriptContent = Get-Content (Join-Path $PSScriptRoot 'build.ps1') -Raw
$buildScriptAst = [System.Management.Automation.Language.Parser]::ParseInput($buildScriptContent, [ref]$null, [ref]$null)

# Install required modules
if ($buildScriptAst.ScriptRequirements) {
  $buildScriptAst.ScriptRequirements.RequiredModules | ForEach-Object {
    # Collect parameters to pass Install-Module
    $requiredModule = $_
    $params = @{
      Name  = $requiredModule.Name
      Scope = 'CurrentUser'
      Force = $true
    }

    # Pester 5.1 has a bug preventing the codecoverage from being properly computed
    # See https://github.com/pester/Pester/pull/1807
    # The fix will be in 5.2 which has not been released yet and since PowerShell does not support
    # semantic versioning 2.0 (😱), we cannot rely on an alpha version in build.ps1
    # Temporarily force the alpha version here:
    if ('Pester' -eq $params["Name"]) {
      $params['RequiredVersion'] = '5.2.0-alpha3'
      $params['AllowPrerelease'] = $true
    }

    else {
      if ($_.Version)              { $params['MinimumVersion']  = $_.Version }
      elseif ($_.RequiredVersion)  { $params['RequiredVersion'] = $_.RequiredVersion }
      elseif ($_.MaximumVersion)   { $params['MaximumVersion']  = $_.MaximumVersion }
    }

    # Install the module
    [PSCustomObject] $params | Format-Table
    Install-Module @params
  }
}