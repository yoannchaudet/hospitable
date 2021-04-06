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
}