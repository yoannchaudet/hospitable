# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Lists' {
    It 'Outputs nothing when no lists are provided' {
      Get-Lists | Should -BeNullOrEmpty
    }

    It 'Outputs simple lists' {
      (Get-Lists a) -Join [Environment]::NewLine | Should -Be @"
 ─ a
"@
(Get-Lists a, b) -Join [Environment]::NewLine | Should -Be @"
 ─ a
 ─ b
"@
      (Get-Lists a, b, c) -Join [Environment]::NewLine | Should -Be @"
 ─ a
 ─ b
 ─ c
"@
    }

    It 'Outputs lists of lists' {
      (Get-Lists @('a', 'b'), 'c') -Join [Environment]::NewLine | Should -Be @"
┌─ a
└─ b
 ─ c
"@
      (Get-Lists @(,@('a', 'b', 'c'))) -Join [Environment]::NewLine | Should -Be @"
┌─ a
├─ b
└─ c
"@
    }

    It 'Ignore empty nested lists' {
      (Get-Lists @(@(),@('a', 'b', 'c'), 'd', @(), @('e'))) -Join [Environment]::NewLine | Should -Be @"
┌─ a
├─ b
└─ c
 ─ d
 ─ e
"@
    }
  }
}