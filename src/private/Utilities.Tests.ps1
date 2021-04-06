# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'ConvertTo-TwoDimensionsArray' {
    It 'Rejects null values' {
      { ConvertTo-TwoDimensionsArray $null } | Should -Throw
    }

    It 'Rejects non-array values' {
      { ConvertTo-TwoDimensionsArray ([ref] 'test') } | Should -Throw 'Reference was not an array'
    }

    It 'Converts empty arrays' {
      $array = @()
      ConvertTo-TwoDimensionsArray ([ref] $array)
      $array.Count | Should -Be 1
      $array[0] -is [array] | Should -BeTrue
      $array[0].Count | Should -Be 0
    }

    It 'Converts one-dimension arrays' {
      $array = 1, 2
      ConvertTo-TwoDimensionsArray ([ref] $array)
      $array.Count | Should -Be 1
      $array[0] -is [array] | Should -BeTrue
      $array[0].Count | Should -Be 2
      $array[0][0] | Should -Be 1
      $array[0][1] | Should -Be 2
    }

    It 'Maintain two-dimension arrays' {
      $array = ,('test')
      ConvertTo-TwoDimensionsArray ([ref] $array)
      $array.Count | Should -Be 1
      $array[0] -is [array] | Should -BeTrue
      $array[0].Count | Should -Be 1
      $array[0][0] | Should -Be 'test'
    }
  }

  Describe 'Get-MaxArray' {
    It 'Handles empty lists' {
      $l = @(Get-MaxArray @())
      $l.Length | Should -Be 0
    }

    It 'Computes max list (array of array)' {
      $l = @(Get-MaxArray ((1, -2), @(), (2), (0, -1, 3)))
      $l.Length | Should -Be 3
      $l[0] | Should -Be 2
      $l[1] | Should -Be -1
      $l[2] | Should -Be 3
    }

    It 'Computes max list (array)' {
      $l = @(Get-MaxArray (1, 2))
      $l.Length | Should -Be 1
      $l[0] | Should -Be 2
    }
  }
}