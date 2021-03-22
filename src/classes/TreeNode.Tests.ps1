# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'TreeNode.SetColumnAlignment' {
    It 'Sets column alignment just fine' {
      $node = New-TreeNode
      $node.SetColumnAlignment(1, 'left')
      $node.ColumnsAlignment[1] | Should -Be 'left'
      $node.SetColumnAlignment(1, 'centered')
      $node.ColumnsAlignment[1] | Should -Be 'centered'
    }

    It 'Clears column alignment that do not exist' {
      $node = New-TreeNode
      $node.SetColumnAlignment(6, $null)
      $node.ColumnsAlignment.ContainsKey(6) | Should -Be $False
    }

    It 'Clears column alignment that do exist' {
      $node = New-TreeNode
      $node.SetColumnAlignment(1, 'left')
      $node.ColumnsAlignment[1] | Should -Be 'left'
      $node.SetColumnAlignment(1, $null)
      $node.ColumnsAlignment.ContainsKey(1) | Should -Be $False
    }
  }
}