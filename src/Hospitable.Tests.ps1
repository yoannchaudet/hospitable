Describe 'Hospitable module' {
  It 'Explicitly functions to exports' {
    # Load the module manifest
    $module = Test-ModuleManifest -Path (Join-Path $PSScriptRoot 'Hospitable.psd1')

    # Collect all public functions we should export
    $functions = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'public') -Exclude '*.Tests.ps1').BaseName

    # Assert for missing functions
    $functions | ForEach-Object {
      [string[]] $module.ExportedFunctions.Keys | Should -Contain $_
    }

    # Assert for extra functions
    [string[]] $module.ExportedFunctions.Keys | ForEach-Object {
      $functions | Should -Contain $_
    }
  }
}