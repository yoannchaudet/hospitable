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

  Describe 'TreeNode.ComputeColumnsMaxLengthPerDepth' {
    It 'Recursively compute the max length per depth (1-column tree)' {
      # Create a simple tree
      $node = New-TreeNode
      $node.AddChild('b').AddChild('cccc') | Out-Null

      # Compute max length per depth
      $columnsMaxLengthPerDepth = @{}
      $node.ComputeColumnsMaxLengthPerDepth($columnsMaxLengthPerDepth, 0)
      $columnsMaxLengthPerDepth.Count | Should -Be 2
      $columnsMaxLengthPerDepth[0][0] | Should -Be 1
      $columnsMaxLengthPerDepth[1][0] | Should -Be 4
    }

    It 'Recursively compute the max length per depth (n-column tree)' {
      # Create a simple tree
      $node = New-TreeNode
      $node.AddChild(@('c1', 'c2', 'c3')).AddChild(@('a', 'aa'))
      $node.AddChild('a single long column')
      $node.AddChild(@('c1', 'c', 'ccc'))

      # Compute max length per depth
      $columnsMaxLengthPerDepth = @{}
      $node.ComputeColumnsMaxLengthPerDepth($columnsMaxLengthPerDepth, 0)
      $columnsMaxLengthPerDepth.Count | Should -Be 2
      $columnsMaxLengthPerDepth[0][0] | Should -Be 'a single long column'.Length
      $columnsMaxLengthPerDepth[0][1] | Should -Be 2
      $columnsMaxLengthPerDepth[0][2] | Should -Be 3
      $columnsMaxLengthPerDepth[1][0] | Should -Be 1
      $columnsMaxLengthPerDepth[1][1] | Should -Be 2
    }
  }
}