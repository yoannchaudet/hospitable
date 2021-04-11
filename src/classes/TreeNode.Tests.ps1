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
      $node.Columns[0].Alignment | Should -Be 'Left'
      $node.Columns[1].Text | Should -Be ('col2' | Get-Bold)
      $node.Columns[1].TextLength | Should -Be (Get-FormattedStringLength ('col2' | Get-Bold))
      $node.Columns[1].Alignment | Should -Be 'Left'
      $node.Children.Count | Should -Be 0
    }

    It 'Sets depth' {
      $node = [TreeNode]::New(@())
      $node.Depth | Should -Be 0
    }

    It 'Sets alignment group' {
      $node = [TreeNode]::New(@())
      $node.AlignmentGroup | Should -Be 0
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
      $child.Columns[0].Alignment | Should -Be 'Left'
    }

    It 'Add children (n-column)' {
      $node = New-Tree
      $node.Children.Count | Should -Be 0
      $child = $node.AddChild(@(1, 2, 3))
      $node.Children.Count | Should -Be 1
      $child.Columns.Count | Should -Be 3
    }

    It 'Increases depth' {
      $node = (New-Tree).AddChild('1')
      $node.Depth | Should -Be 1
      ($node.AddChild('2')).Depth | Should -Be 2
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
      $child1.Columns[0].Alignment | Should -Be 'Left' # No inheritance

      $child2 = $node.AddChild(@('col1', 'col2', 'col3'))
      $child2.Columns.Count | Should -Be 3
      $child2.Columns[0].Alignment | Should -Be 'Left'
      $child2.Columns[1].Alignment | Should -Be 'Centered'
      $child2.Columns[2].Alignment | Should -Be 'Left'

      $child3 = $node.AddChild(@('col1', 'col2', 'col3', 'col4'))
      $child3.Columns.Count | Should -Be 4
      $child3.Columns[0].Alignment | Should -Be 'Left'
      $child3.Columns[1].Alignment | Should -Be 'Centered'
      $child3.Columns[2].Alignment | Should -Be 'Left'
      $child3.Columns[3].Alignment | Should -Be 'Right'
    }

    It 'Inherits alignment group' {
      $node = New-Tree
      $node.AlignmentGroup = 1
      $node.AddChild('test').AlignmentGroup | Should -Be 1
    }
  }

  Describe 'TreeNode.SetColumnAlignment' {
    It 'Sets alignment on existing columns' {
      $node = (New-Tree).AddChild(@('col1', 'col2'))
      @('Left', 'Right', 'Centered') | ForEach-Object {
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
      $node.SetColumnAlignment(-1, 'Left')
      $node.Columns.Count | Should -Be 0
      $node.SetColumnAlignment(-2, 'Left')
      $node.Columns.Count | Should -Be 0
    }

    It 'Adds empty columns when needed' {
      $node = New-Tree
      $node.Columns.Count | Should -Be 0
      $node.SetColumnAlignment(1, 'Right')
      $node.Columns.Count | Should -Be 2
      $node.Columns[0].Text | Should -Be ''
      $node.Columns[0].TextLength | Should -Be 0
      $node.Columns[0].Alignment | Should -Be 'Left'
      $node.Columns[1].Text | Should -Be ''
      $node.Columns[1].TextLength | Should -Be 0
      $node.Columns[1].Alignment | Should -Be 'Right'
    }
  }

  Describe 'TreeNode.FormatChildren' {
    It 'Recursively format children' {
      $node = New-Tree
      $a = $node.AddChild('a')
      $b = $a.AddChild('b ')
      $c = $b.AddChild(@('c1', 'c2', 'c3'))

      $a.Columns[0].ColumnLength = 1
      $b.Columns[0].ColumnLength = 3
      $c.Columns[0].ColumnLength = 3
      $c.Columns[1].ColumnLength = 4
      $c.Columns[2].ColumnLength = 6

      # Default alignment (left)
      $node.FormatChildren(1)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been trimmed
      $c.Label | Should -Be 'c1  c2   c3'

      # Explicit left alignment
      $a.SetColumnAlignment(0, 'Left')
      $b.SetColumnAlignment(0, 'Left')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Left') }
      $node.FormatChildren(2)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be 'b' # 'b ' should have been right trimmed
      $c.Label | Should -Be 'c1   c2    c3'

      # Right alignment
      $a.SetColumnAlignment(0, 'Right')
      $b.SetColumnAlignment(0, 'Right')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Right') }
      $node.FormatChildren(1)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be '  b'
      $c.Label | Should -Be ' c1   c2     c3'

      # Centered alignment
      $a.SetColumnAlignment(0, 'Centered')
      $b.SetColumnAlignment(0, 'Centered')
      0..2 | ForEach-Object { $c.SetColumnAlignment($_, 'Centered') }
      $node.FormatChildren(1)
      $a.Label | Should -Be 'a'
      $b.Label | Should -Be ' b' # should be right trimmed
      $c.Label | Should -Be ' c1  c2    c3'

      # Mix alignment
      $c.SetColumnAlignment(0, 'Right')
      $c.SetColumnAlignment(1, 'Left')
      $c.SetColumnAlignment(2, 'Centered')
      $node.FormatChildren(1)
      $c.Label | Should -Be ' c1 c2     c3'
    }

    It 'Formats children that are using text formatting' {
      $node = New-Tree
      $a = $node.AddChild((Get-Bold "a"))

      $a.Columns[0].ColumnLength = 3

      # Default alignment (left)
      $node.FormatChildren(1)
      $a.Label | Should -Be "$('a' | Get-Bold)"

      # Left alignment
      $a.SetColumnAlignment(0, 'Right')
      $node.FormatChildren(1)
      $a.Label | Should -Be "  $('a' | Get-Bold)"

      # Centered alignment
      $a.SetColumnAlignment(0, 'Centered')
      $node.FormatChildren(1)
      $a.Label | Should -Be " $('a' | Get-Bold)"

      # Centered alignment (unbalanced)
      $a.Columns[0].ColumnLength = 6
      $node.FormatChildren(1)
      $a.Label | Should -Be "   $('a' | Get-Bold)"
    }
  }
}