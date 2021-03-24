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
      $node.AddChild('b').AddChild('cccc')

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

  Describe 'TreeNode.FormatChildren' {
    It 'Recursively format children' {
      $node = New-TreeNode
      $a = $node.AddChild('a')
      $b = $a.AddChild('b ')
      $c = $b.AddChild(@('c1', 'c2', 'c3'))

      $columnsMaxLengthPerDepth = @{}
      $columnsMaxLengthPerDepth[0] = @(1)
      $columnsMaxLengthPerDepth[1] = @(3)
      $columnsMaxLengthPerDepth[2] = @(3, 4, 6)

      # Default alignment (left)
      $node.FormatChildren(1, $columnsMaxLengthPerDepth, 0)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been trimmed
      $c.Label | Should -Be 'c1  c2   c3'

      # Explicit left alignment
      $a.SetColumnAlignment(0, 'left')
      $b.SetColumnAlignment(0, 'left')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'left') }
      $node.FormatChildren(2, $columnsMaxLengthPerDepth, 0)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been right trimmed
      $c.Label | Should -Be 'c1   c2    c3'

      # Right alignment
      $a.SetColumnAlignment(0, 'right')
      $b.SetColumnAlignment(0, 'right')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'right') }
      $node.FormatChildren(1, $columnsMaxLengthPerDepth, 0)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be '  b'
      $c.Label | Should -Be ' c1   c2     c3'

      # Centered alignment
      $a.SetColumnAlignment(0, 'centered')
      $b.SetColumnAlignment(0, 'centered')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'centered') }
      $node.FormatChildren(1, $columnsMaxLengthPerDepth, 0)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be ' b' # should be right trimmed
      $c.Label | Should -Be ' c1  c2    c3'

      # Mix alignment
      $c.SetColumnAlignment(0, 'right')
      $c.SetColumnAlignment(1, 'left')
      $c.SetColumnAlignment(2, 'centered')
      $node.FormatChildren(1, $columnsMaxLengthPerDepth, 0)
      $c.Label | Should -Be ' c1 c2     c3'
    }
  }
}