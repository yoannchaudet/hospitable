﻿# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-SettingValue' {
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