# Load (or reload) the module
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

  Describe 'Get-FormattedStringLength' {
    It 'Supports null and empty strings' {
      Get-FormattedStringLength | Should -Be 0
      Get-FormattedStringLength '' | Should -Be 0
    }

    It 'Supports strings not containing modifiers' {
      Get-FormattedStringLength 'a' | Should -Be 1
      Get-FormattedStringLength 'hello' | Should -Be 5
      Get-FormattedStringLength 'hello 🤠' | Should -Be 'hello 🤠'.Length
      Get-FormattedStringLength "  `nline 1`nlines 2 " | Should -Be "  `nline 1`nlines 2 ".Length
    }

    It 'Supports valid text formatting' {
      Get-FormattedStringLength (Get-Bold 'hello') | Should -Be 5
      Get-FormattedStringLength ('hello 🤠' | Get-Bold | Get-Underline) | Should -Be 'hello 🤠'.Length
      Get-FormattedStringLength ("  `nline 1`nlines 2 " | Get-Bold | Get-Underline | Get-Negative) | Should -Be "  `nline 1`nlines 2 ".Length
      Get-FormattedStringLength @('a', (Get-Bold 'b'), (Get-Negative 'c'), (Get-Underline 'd')) -Join ' ' | Should -Be 7
    }
  }
}