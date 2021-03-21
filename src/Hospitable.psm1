#Requires -version 7.0

# Init (applies to the entire module)
Set-StrictMode -version 'Latest'
$ErrorActionPreference = 'Stop'

# Dot-source all files (outside of the tests)
@('public', 'private', 'classes') | ForEach-Object {
  $path = Join-Path $PSScriptRoot "$_/*.ps1"
  (Set-Variable -Name $_ -Value @(Get-ChildItem -Path $path -Exclude '*.Tests.ps1') -PassThru).Value | ForEach-Object {
    $file = $_.FullName
    try {
      . $file
    } catch {
      throw "Error importing file $file, $_"
    }
  }
}

# Export public cmdlets
Export-ModuleMember -Function $public.BaseName