# Import the module
. (Join-Path $PSScriptRoot '../TestHeader.Tests.ps1')

InModuleScope Hospitable {
  Describe 'Get-SettingValue' {
    BeforeEach {
      Remove-Variable -Name 'HOSPITABLE_TEST' -Scope 'global' -Force -ErrorAction 'SilentlyContinue'
    }

    It 'Returns default value when no override is defined' {
      Get-SettingValue -Setting 'TEST' -DefaultValue 'default value' | Should -Be 'default value'
    }

    It 'Returns default value when the override is null or empty' {
      $global:HOSPITABLE_TEST = ''
      Get-SettingValue -Setting 'TEST' -DefaultValue 'default value' | Should -Be 'default value'

      $global:HOSPITABLE_TEST = $null
      Get-SettingValue -Setting 'TEST' -DefaultValue 'default value' | Should -Be 'default value'
    }

    It 'Returns the override when it is defined' {
      $global:HOSPITABLE_TEST = 'override value'
      Get-SettingValue -Setting 'TEST' -DefaultValue 'default value' | Should -Be 'override value'
    }
  }
}