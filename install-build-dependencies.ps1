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
    if ($_.Version)              { $params['MinimumVersion']  = $_.Version }
    elseif ($_.RequiredVersion)  { $params['RequiredVersion'] = $_.RequiredVersion }
    elseif ($_.MaximumVersion)   { $params['MaximumVersion']  = $_.MaximumVersion }

    # Install the module
    [PSCustomObject] $params | Format-Table
    Install-Module @params
  }
}