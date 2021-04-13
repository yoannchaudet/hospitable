# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Tree' {
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
        { Get-Tree {} -Prefixes @($_) } | Should -Throw
      }
    }

    It 'Formats one-root tree' {
      # Create a tree
      $tree = {
        Node 'root' {
          Node 'node 1' {
            Node 'subnode 1'
            Node 'subnode 2'
          }
          Node 'node 2'
        }
      }

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ node 1
│  ├─ subnode 1
│  └─ subnode 2
└─ node 2
"@
    }

    It 'Formats n-root tree' {
      # Create a tree
      $tree = {
        Node 'root 1' {
          Node 'subnode 1'
          Node 'subnode 2'
        }
        Node 'root 2'
      }

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
      $tree = {
        Node 'col1', 'col2'
        Node 'col3', 'col4'
      }

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree -SpacesBetweenColumns 3) -Join [Environment]::NewLine
      $tree | Should -Be @"
col1   col2
col3   col4
"@
    }

    It 'Formats trees with columns' {
      # Create a tree
      $tree = {
        Node 'root' {
          Node 'col1', 'col2'
          Node 'another node'
        }
      }

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ col1         col2
└─ another node
"@
    }

    It 'Formats trees with columns and alignment' {
      # Create a tree
      $tree = {
        Node 'root' {
          ChildrenColumnAlignment 0 'Right'
          ChildrenColumnAlignment 1 'Centered'

          Node 'col1', 'col2', 'col3'
          Node 'some text'
          Node 1, 2, 3 {
            ColumnAlignment 0 'Left'
          }
        }
      }

      # Verify it gets formatted fine
      $tree = @(Get-Tree $tree) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─      col1 col2 col3
├─ some text
└─ 1           2  3
"@
    }

    It 'Formats tree with alignment groups (default)' {
      # Create a tree
      $tree = {
        Node 'a', 'b', 'c' {
          Node 'aa', 'bb', 'cc' {
            Node 'aaa', 'bbb', 'ccc'
          }
        }
      }

      # Default padding (all nodes in the same group)
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa     bb  cc
   └─ aaa bbb ccc
"@
    }

    It 'Formats tree with alignment groups (inherited)' {
      # Create a tree
      $tree = {
        Node 'a', 'b', 'c' {
          ChildrenAlignmentGroup 1
          Node 'aa', 'bb', 'cc' {
            Node 'aaa', 'bbb', 'ccc'
          }
        }
      }

      # Default padding (all nodes in the same group)
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a b c
└─ aa     bb  cc
   └─ aaa bbb ccc
"@
    }

    It 'Formats tree with alignment groups (explicit)' {
      # Create a tree
      $tree = {
        Node 'a', 'b', 'c' {
          Node 'aa', 'bb', 'cc' {
            AlignmentGroup 1
            Node 'aaa', 'bbb', 'ccc'
          }
        }
      }

      # Default padding (all nodes in the same group)
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
a         b   c
└─ aa bb cc
   └─ aaa bbb ccc
"@
    }
  }
}