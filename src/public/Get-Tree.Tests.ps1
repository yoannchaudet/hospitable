# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Tree' {
    It 'Throws when an invalid root is passed' {
      { Get-Tree 'test' } | Should -Throw 'Root is invalid'
    }

    It 'Throws when prefixes are of different lengths' {
      try {
        $badPrefixes = @(
          @('a', 'b', 'cc'),
          @('a', 'bb', 'c'),
          @('aa', 'b', 'c')
        )
        $badPrefixes | ForEach-Object {
          {
            $global:HOSPITABLE_TREE_IN_PREFIX = $_[0]
            $global:HOSPITABLE_TREE_BRANCH_PREFIX = $_[1]
            $global:HOSPITABLE_TREE_LEAF_PREFIX = $_[2]
            Get-Tree (New-Tree)
          } | Should -Throw 'Prefixes are either not all provided or of different lengths'
        }
      } finally {
        Remove-Variable -Name HOSPITABLE_TREE_IN_PREFIX -Scope 'Global' -Force
        Remove-Variable -Name HOSPITABLE_TREE_BRANCH_PREFIX -Scope 'Global' -Force
        Remove-Variable -Name HOSPITABLE_TREE_LEAF_PREFIX -Scope 'Global' -Force
      }
    }

    It 'Formats one-node tree' {
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

    It 'Formats n-node tree' {
      # Create a tree
      $tree = New-Tree
      $node0 = $tree.AddChild('node 0')
      $node0.AddChild('subnode 1')
      $node0.AddChild('subnode 2')
      $tree.AddChild('node 1')

      # Verify we can format multiple parts of the tree as roots
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
node 0
├─ subnode 1
└─ subnode 2
node 1
"@
    }

    It 'Formats trees with columns at the root (+ SpacesBetweenColumns)' {
      # Create a tree
      $tree = New-Tree
      $tree.AddChild(@('col1', 'col2'))
      $tree.AddChild(@('col3', 'col4'))

      # Verify it gets formatted fine
      try {
        $global:HOSPITABLE_TREE_SPACES_BETWEEN_COLUMNS = 3
        $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
        $tree | Should -Be @"
col1   col2
col3   col4
"@
      } finally {
        Remove-Variable HOSPITABLE_TREE_SPACES_BETWEEN_COLUMNS -Scope 'global' -Force
      }
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
      $root.SetColumnAlignment(0, 'Right')
      $root.SetColumnAlignment(1, 'Centered')
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
      $n3 = $n2.AddChild(@('aaa', 'bbb', 'ccc'))

      # Regular formatting
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a b c
└─ aa bb cc
   └─ aaa bbb ccc
"@

      # With alignment groups
      $out = @(Get-Tree $tree -AlignmentGroups @(, @($n1, $n2, $n3))) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa     bb  cc
   └─ aaa bbb ccc
"@

      # With multiple alignment groups
      $out = @(Get-Tree $tree -AlignmentGroups @($n2),@($n1, $n3)) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa bb cc
   └─ aaa bbb ccc
"@

      # With multiple alignment groups
      $out = @(Get-Tree $tree -AlignmentGroups @(),$null,@($n2,'test'),@(0, $n1, $false, $n3)) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa bb cc
   └─ aaa bbb ccc
"@
    }
  }
}