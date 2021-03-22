# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'New-TreeNode' {
    It 'Creates empty tree node' {
      $node = New-TreeNode
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 0
      $node.Children.Count | Should -Be 0
    }

    It 'Creates one-column tree node' {
      $node = New-TreeNode 'label'
      $node.Label | Should -Be 'label'
      $node.Columns.Count | Should -Be 0
      $node.Children.Count | Should -Be 0
    }

    It 'Creates n-column tree node' {
      $node = New-TreeNode 'col1', 'col2'
      $node.Label | Should -Be 'col1'
      $node.Columns.Count | Should -Be 2
      $node.Columns[0] | Should -Be 'col1'
      $node.Columns[1] | Should -Be 'col2'
      $node.Children.Count | Should -Be 0
    }
  }
}