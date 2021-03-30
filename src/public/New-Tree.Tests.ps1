# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'New-Tree' {
    It 'Creates empty tree node' {
      $node = New-Tree
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 0
      $node.Children.Count | Should -Be 0
    }
  }
}