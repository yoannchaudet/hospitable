# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Tree' {
    It 'Throws when an invalid root is passed' {
      { Get-Tree 'test' } | Should -Throw 'Root is invalid'
    }

    It 'Throws when prefixes are not provided or are of different lengths' {
      $badPrefixes = @(
        @('a', 'b', 'cc'),
        @('a', 'bb', 'c'),
        @('aa', 'b', 'c'),
        @($null, 'b', 'c'),
        @('a', $null, 'c'),
        @('a', 'b', $null),
        @($null, $null, $null)
      )
      $badPrefixes | ForEach-Object {
        { Get-Tree (New-Tree) `
            -TreeInPrefix $_[0] `
            -TreeBranchPrefix $_[1] `
            -TreeLeafPrefix $_[2]
        } | Should -Throw 'Prefixes are either not all provided or of different lengths'
      }
    }

    It 'Formats one-root tree' {
      # Create a tree
      $tree = New-Tree
      $root = $tree.AddChild('root')
      $node1 = $root.AddChild('node1')
      $node1.AddChild('subnode 1')
      $node1.AddChild('subnode 2')
      $root.AddChild('node2' )

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ node1
│  ├─ subnode 1
│  └─ subnode 2
└─ node2
"@
    }

    It 'Formats n-root tree' {
      # Create a tree
      $tree = New-Tree
      $root1 = $tree.AddChild('root 1')
      $root1.AddChild('subnode 1')
      $root1.AddChild('subnode 2')
      $tree.AddChild('root 2')

      # Verify we can format multiple parts of the tree as roots
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root 1
├─ subnode 1
└─ subnode 2
root 2
"@
    }

    It 'Formats trees with columns at the root (+ SpacesBetweenColumns)' {
      # Create a tree
      $tree = New-Tree
      $tree.AddChild(@('col1', 'col2'))
      $tree.AddChild(@('col3', 'col4'))

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree -SpacesBetweenColumns 3) -Join [Environment]::NewLine
      $tree | Should -Be @"
col1   col2
col3   col4
"@
    }

    It 'Formats trees with columns' {
      # Create a tree
      $tree = New-Tree
      $root = $tree.AddChild('root')
      $root.AddChild(@('col1', 'col2'))
      $root.AddChild('another column')

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ col1           col2
└─ another column
"@
    }

    It 'Formats trees with columns and alignment' {
      # Create a tree
      $tree = New-Tree
      $root = $tree.AddChild('root')
      $root.SetChildrenColumnAlignment(0, 'Right')
      $root.SetChildrenColumnAlignment(1, 'Centered')
      $root.AddChild(@('col1', 'col2', 'col3'))
      $root.AddChild('some text')
      $lastNode = $root.AddChild(@('1', '2', '3'))
      $lastNode.SetColumnAlignment(0, 'Left') # test overwride

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─      col1 col2 col3
├─ some text
└─ 1           2  3
"@
    }

    It 'Formats tree with alignment groups' {
      # Create a tree
      $tree = New-Tree
      $n1 = $tree.AddChild(@('a', 'b', 'c'))
      $n2 = $n1.AddChild(@('aa', 'bb', 'cc'))
      $n2.AddChild(@('aaa', 'bbb', 'ccc'))

      # Default padding (all nodes in the same group)
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa     bb  cc
   └─ aaa bbb ccc
"@

      # With multiple alignment groups
      $n2.AlignmentGroup = 2
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa bb cc
   └─ aaa bbb ccc
"@
    }
  }
}