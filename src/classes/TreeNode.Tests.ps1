# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'TreeNode.ctor' {
    It 'Creates empty tree node' {
      $node = [TreeNode]::New(@())
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 0
      $node.Children.Count | Should -Be 0
    }

    It 'Creates one-column tree node' {
      $node = [TreeNode]::New('label')
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 1
      $node.Children.Count | Should -Be 0
    }

    It 'Creates n-column tree node' {
      $node = [TreeNode]::New(@('col1', ('col2' | Get-Bold)))
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 2
      $node.Columns[0].Text | Should -Be 'col1'
      $node.Columns[0].TextLength | Should -Be 4
      $node.Columns[0].Alignment | Should -Be 'Default'
      $node.Columns[1].Text | Should -Be ('col2' | Get-Bold)
      $node.Columns[1].TextLength | Should -Be (Get-FormattedStringLength ('col2' | Get-Bold))
      $node.Columns[1].Alignment | Should -Be 'Default'
      $node.Children.Count | Should -Be 0
    }
  }

  Describe 'TreeNode.AddChild' {
    It 'Validates columns is not null' {
      $node = New-Tree
      { $node.AddChild($null) } | Should -Throw
    }

    It 'Add children (1-column)' {
      $node = New-Tree
      $node.Children.Count | Should -Be 0
      $child = $node.AddChild('')
      $node.Children.Count | Should -Be 1
      $child.Columns.Count | Should -Be 1
      $child.Columns[0].Text | Should -Be ''
      $child.Columns[0].TextLength | Should -Be 0
      $child.Columns[0].Alignment | Should -Be 'Default'
    }

    It 'Add children (n-column)' {
      $node = New-Tree
      $node.Children.Count | Should -Be 0
      $child = $node.AddChild(@(1, 2, 3))
      $node.Children.Count | Should -Be 1
      $child.Columns.Count | Should -Be 3
    }

    It 'Inherits parent alignments' {
      $node = (New-Tree).AddChild(@('test'))
      $node.SetColumnAlignment(0, 'Right')
      $child = $node.AddChild('child')
      $child.Columns[0].Alignment | Should -Be 'Right'
    }

    It 'Inherits parent alignments even with ghost columns' {
      $node = New-Tree
      $node.SetColumnAlignment(1, 'Centered')
      $node.SetColumnAlignment(3, 'Right')

      $child1 = $node.AddChild('col1')
      $child1.Columns.Count | Should -Be 1
      $child1.Columns[0].Alignment | Should -Be 'Default' # No inheritance

      $child2 = $node.AddChild(@('col1', 'col2', 'col3'))
      $child2.Columns.Count | Should -Be 3
      $child2.Columns[0].Alignment | Should -Be 'Default'
      $child2.Columns[1].Alignment | Should -Be 'Centered'
      $child2.Columns[2].Alignment | Should -Be 'Default'

      $child3 = $node.AddChild(@('col1', 'col2', 'col3', 'col4'))
      $child3.Columns.Count | Should -Be 4
      $child3.Columns[0].Alignment | Should -Be 'Default'
      $child3.Columns[1].Alignment | Should -Be 'Centered'
      $child3.Columns[2].Alignment | Should -Be 'Default'
      $child3.Columns[3].Alignment | Should -Be 'Right'
    }
  }

  Describe 'TreeNode.SetColumnAlignment' {
    It 'Sets alignment on existing columns' {
      $node = (New-Tree).AddChild(@('col1', 'col2'))
      @('Default', 'Left', 'Right', 'Centered') | ForEach-Object {
        $node.SetColumnAlignment(1, $_)
        $node.Columns[1].Alignment | Should -Be $_
      }
    }

    It 'Validates the alignment type' {
      $node = New-Tree
      { $node.SetColumnAlignment(0, $null) } | Should -Throw
      { $node.SetColumnAlignment(0, 'BadAlignment') } | Should -Throw
    }

    It 'Ignore negative indices' {
      $node = New-Tree
      $node.SetColumnAlignment(-1, 'Default')
      $node.Columns.Count | Should -Be 0
      $node.SetColumnAlignment(-2, 'Default')
      $node.Columns.Count | Should -Be 0
    }

    It 'Adds empty columns when needed' {
      $node = New-Tree
      $node.Columns.Count | Should -Be 0
      $node.SetColumnAlignment(1, 'Right')
      $node.Columns.Count | Should -Be 2
      $node.Columns[0].Text | Should -Be ''
      $node.Columns[0].TextLength | Should -Be 0
      $node.Columns[0].Alignment | Should -Be 'Default'
      $node.Columns[1].Text | Should -Be ''
      $node.Columns[1].TextLength | Should -Be 0
      $node.Columns[1].Alignment | Should -Be 'Right'
    }
  }

  Describe 'TreeNode.GetMaxList' {
    It 'Handles null or empty lists' {
      $l = [TreeNode]::GetMaxList($null)
      $l.Length | Should -Be 0

      $l = [TreeNode]::GetMaxList(@())
      $l.Length | Should -Be 0
    }

    It 'Computes max list (array of array)' {
      $l = [TreeNode]::GetMaxList(@($null, @(1, -2), @(), @(2), @(0, -1, 3)))
      $l.Length | Should -Be 3
      $l[0] | Should -Be 2
      $l[1] | Should -Be -1
      $l[2] | Should -Be 3
    }

    It 'Computes max list (array)' {
      $l = [TreeNode]::GetMaxList(@(1, 2))
      $l.Length | Should -Be 1
      $l[0] | Should -Be 2
    }
  }

  Describe 'TreeNode.ComputeColumnsMaxLengthPerParent' {
    It 'Recursively compute the max length per parent (1-column tree)' {
      # Create a simple tree
      $tree = New-Tree
      $tree.AddChild('b').AddChild('cccc')

      # Compute max length per parent
      $columnsMaxLengthPerParent = @{}
      [TreeNode]::ComputeColumnsMaxLengthPerParent($columnsMaxLengthPerParent, $tree)
      $columnsMaxLengthPerParent.Count | Should -Be 2
      $columnsMaxLengthPerParent[$tree][0] | Should -Be 1
      $columnsMaxLengthPerParent[$tree.Children[0]][0] | Should -Be 4
    }

    It 'Recursively compute the max length per depth (n-column tree)' {
      # Create a simple tree
      $tree = New-Tree
      $tree.AddChild(@('c1', 'c2', 'c3')).AddChild(@('a', 'aa'))
      $tree.AddChild('a single long column')
      $tree.AddChild(@('c1', 'c', 'ccc'))

      # Compute max length per parent
      $columnsMaxLengthPerParent = @{}
      [TreeNode]::ComputeColumnsMaxLengthPerParent($columnsMaxLengthPerParent, $tree)
      $columnsMaxLengthPerParent.Count | Should -Be 2
      $columnsMaxLengthPerParent[$tree][0] | Should -Be 'a single long column'.Length
      $columnsMaxLengthPerParent[$tree][1] | Should -Be 2
      $columnsMaxLengthPerParent[$tree][2] | Should -Be 3
      $columnsMaxLengthPerParent[$tree.Children[0]][0] | Should -Be 1
      $columnsMaxLengthPerParent[$tree.Children[0]][1] | Should -Be 2
    }
  }

  Describe 'TreeNode.FormatChildren' {
    It 'Recursively format children' {
      $node = New-Tree
      $a = $node.AddChild('a')
      $b = $a.AddChild('b ')
      $c = $b.AddChild(@('c1', 'c2', 'c3'))

      $columnsMaxLengthPerParent = @{}
      $columnsMaxLengthPerParent[$node] = @(1)
      $columnsMaxLengthPerParent[$a] = @(3)
      $columnsMaxLengthPerParent[$b] = @(3, 4, 6)

      # Default alignment (left)
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been trimmed
      $c.Label | Should -Be 'c1  c2   c3'

      # Explicit left alignment
      $a.SetColumnAlignment(0, 'Left')
      $b.SetColumnAlignment(0, 'Left')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Left') }
      $node.FormatChildren(2, $columnsMaxLengthPerParent)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been right trimmed
      $c.Label | Should -Be 'c1   c2    c3'

      # Right alignment
      $a.SetColumnAlignment(0, 'Right')
      $b.SetColumnAlignment(0, 'Right')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Right') }
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be '  b'
      $c.Label | Should -Be ' c1   c2     c3'

      # Centered alignment
      $a.SetColumnAlignment(0, 'Centered')
      $b.SetColumnAlignment(0, 'Centered')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Centered') }
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be ' b' # should be right trimmed
      $c.Label | Should -Be ' c1  c2    c3'

      # Mix alignment
      $c.SetColumnAlignment(0, 'Right')
      $c.SetColumnAlignment(1, 'Left')
      $c.SetColumnAlignment(2, 'Centered')
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $c.Label | Should -Be ' c1 c2     c3'
    }

    It 'Formats children that are using text formatting' {
      $node = New-Tree
      $a = $node.AddChild((Get-Bold "a"))

      $columnsMaxLengthPerParent = @{}
      $columnsMaxLengthPerParent[$node] = @(3)

      # Default alignment (left)
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be "$('a' | Get-Bold)"

      # Left alignment
      $a.SetColumnAlignment(0, 'Right')
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be "  $('a' | Get-Bold)"

      # Centered alignment
      $a.SetColumnAlignment(0, 'Centered')
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be " $('a' | Get-Bold)"

      # Centered alignment (unbalanced)
      $columnsMaxLengthPerParent[$node] = @(6)
      $node.FormatChildren(1, $columnsMaxLengthPerParent)
      $a.Label | Should -Be "   $('a' | Get-Bold)"
    }
  }
}