# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-MaxArray' {
    It 'Handles empty lists' {
      $l = @(Get-MaxArray @())
      $l.Length | Should -Be 0
    }

    It 'Computes max list (array of array)' {
      $l = @(Get-MaxArray @(@(1, -2), @(), (2), @(0, -1, 3)))
      $l.Length | Should -Be 3
      $l[0] | Should -Be 2
      $l[1] | Should -Be -1
      $l[2] | Should -Be 3
    }

    It 'Computes max list (array)' {
      $l = @(Get-MaxArray @(1, 2))
      $l.Length | Should -Be 1
      $l[0] | Should -Be 2
    }
  }
}