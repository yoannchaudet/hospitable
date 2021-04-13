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

  Describe 'Confirm-ValidPrefixes' {
    It 'Validates prefixes count' {
      { Confirm-ValidPrefixes -Prefixes @() -PrefixesCount 1 } | Should -Throw "Invalid number of prefixes provided (expected = 1)"
      { Confirm-ValidPrefixes -Prefixes @($null) -PrefixesCount 1 } | Should -Throw "Invalid number of prefixes provided (expected = 1)"
      { Confirm-ValidPrefixes -Prefixes @($null, 'test') -PrefixesCount 1 } | Should -Throw "Invalid number of prefixes provided (expected = 1)"
      { Confirm-ValidPrefixes -Prefixes @($null, 'test') -PrefixesCount 2 } | Should -Throw "Invalid number of prefixes provided (expected = 2)"
      { Confirm-ValidPrefixes -Prefixes @('test', 'test') -PrefixesCount 1 } | Should -Throw "Invalid number of prefixes provided (expected = 1)"
      { Confirm-ValidPrefixes -Prefixes @('test', 'test') -PrefixesCount 2 } | Should -Not -Throw "Invalid number of prefixes provided (expected = 1)"
    }

    It 'Validates prefixes are of the same length' {
      Confirm-ValidPrefixes -Prefixes @('a') -PrefixesCount 1 -SameLength | Should -Be 1
      Confirm-ValidPrefixes -Prefixes @('aa', 'bb', 'cc') -PrefixesCount 3 -SameLength | Should -Be 2
      { Confirm-ValidPrefixes -Prefixes @('aa', 'b', 'cc') -PrefixesCount 3 -SameLength } | Should -Throw "Prefixes must all have the same length"
    }
  }
}