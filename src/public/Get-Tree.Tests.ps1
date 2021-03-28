# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Tree' {
    It 'Formats one-root trees' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $node1 = $root.AddChild('node1')
      $node1.AddChild('subnode 1') | Out-Null
      $node1.AddChild('subnode 2') | Out-Null
      $root.AddChild('node2') | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ node1
│  ├─ subnode 1
│  └─ subnode 2
└─ node2
"@
    }

    It 'Formats n-roots trees' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $node1 = $root.AddChild('node1')
      $node1.AddChild('subnode 1') | Out-Null
      $node1.AddChild('subnode 2') | Out-Null
      $node2 = $root.AddChild('node2')

      # Verify we can format multiple parts of the tree as roots
      $tree = @(Get-Tree -Roots @($root, $node1, $node2)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ node1
│  ├─ subnode 1
│  └─ subnode 2
└─ node2
node1
├─ subnode 1
└─ subnode 2
node2
"@
    }

    It 'Formats one-root trees with columns' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $node1 = $root.AddChild('node1')
      $node1.AddChild(@('a first column', 'another one', 'and again')) | Out-Null
      $node1.AddChild(@('c1', 'c2')) | Out-Null
      $node1.AddChild(@('c1', 'c2', 'c3', 'c4')) | Out-Null
      $root.AddChild('node2') | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ node1
│  ├─ a first column another one and again
│  ├─ c1             c2
│  └─ c1             c2          c3        c4
└─ node2
"@
    }

    It 'Formats n-root tree with columns at the roots' {
      # Create a simple tree
      $root1 = New-TreeNode @('one', 'root')
      $root1.AddChild('node1') | Out-Null
      $root2 = New-TreeNode @('another', 'root')

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root1, $root2)) -Join [Environment]::NewLine
      $tree | Should -Be @"
one     root
└─ node1
another root
"@

      # Verify a single root works too
      $tree = @(Get-Tree -Roots @(New-TreeNode @('another', 'root'))) -Join [Environment]::NewLine
      $tree | Should -Be @"
another root
"@
    }

    It 'Formats n-root trees with columns and alignments' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $root.SetColumnAlignment(2, 'Right')
      $root.AddChild(@('hello', 'world')) | Out-Null
      $root.AddChild(@('bonjour', 'le', 'monde', '!')) | Out-Null
      $root2 = New-TreeNode 'root 2'
      $root2.SetColumnAlignment(0, 'Left')
      $root2.SetColumnAlignment(1, 'Centered')
      $root2.SetColumnAlignment(2, 'Right')
      $root2.AddChild(@('col1', 'col2', '$299.99')) | Out-Null
      $root2.AddChild(@('column 1', 'column 2', 'N/A', '(error)')) | Out-Null
      $root2.AddChild(@('col1', 'x', '$299.99')) | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root, $root2)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ hello    world
└─ bonjour  le         monde !
root 2
├─ col1       col2   `$299.99
├─ column 1 column 2     N/A (error)
└─ col1         x    `$299.99
"@
    }


    It 'Formats n-root trees with columns and alignments and text formatting' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $root.SetColumnAlignment(2, 'Right')
      $root.AddChild(@('hello', (Get-Underline 'world'))) | Out-Null
      $root.AddChild(@('bonjour', 'le', 'monde', '!')) | Out-Null
      $root2 = New-TreeNode 'root 2'
      $root2.SetColumnAlignment(0, 'Left')
      $root2.SetColumnAlignment(1, 'Centered')
      $root2.SetColumnAlignment(2, 'Right')
      $root2.AddChild(@('col1', (Get-Bold 'col2'), '$299.99')) | Out-Null
      $root2.AddChild(@('column 1', 'column 2', 'N/A', '(error)')) | Out-Null
      $root2.AddChild(@('col1', 'x', '$299.99')) | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root, $root2)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─ hello    $(Get-Underline 'world')
└─ bonjour  le         monde !
root 2
├─ col1       $(Get-Bold 'col2')   `$299.99
├─ column 1 column 2     N/A (error)
└─ col1         x    `$299.99
"@
    }

    It 'Formats empty columns fine' {
      # Create a simple tree
      $root = New-TreeNode 'root'
      $root.AddChild(@('', '', 'col3')) | Out-Null
      $root.AddChild(@('', 'col2', '')) | Out-Null
      $root.AddChild(@('', '', 'col3')) | Out-Null
      $root.AddChild(@('col1', 'col2', 'col3')) | Out-Null
      $root.AddChild(@('col1', '', 'col3')) | Out-Null
      $root.AddChild(@('col1', '', '')) | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root
├─           col3
├─      col2
├─           col3
├─ col1 col2 col3
├─ col1      col3
└─ col1
"@
    }

    It 'Supports aligning same depth columns' {
      # Create a tree with columns at multiple depths
      $root1 = New-TreeNode @('root 1', 'col 2')
      $root1.AddChild(@('first node', 'another col', 'again')) | Out-Null
      $root1.AddChild(@('node 2', '', 'some long column')) | Out-Null
      $root2 = New-TreeNode @('a second root', 'col 2')
      $root2.AddChild(@('first node on root 2', 'another col on root 2', 'again on root 2')) | Out-Null
      $root2.AddChild(@('node 2 on root 2', '', 'some long column on root 2')) | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root1, $root2)) -Join [Environment]::NewLine
      $tree | Should -Be @"
root 1        col 2
├─ first node           another col           again
└─ node 2                                     some long column
a second root col 2
├─ first node on root 2 another col on root 2 again on root 2
└─ node 2 on root 2                           some long column on root 2
"@
    }

    It 'Supports aligning cross depth columns' {
      # Create a tree with columns at multiple depths
      $root1 = New-TreeNode @('root 1', 'col 2')
      $root1.AddChild(@('first node', 'another col', 'again')) | Out-Null
      $root1.AddChild(@('node 2', '', 'some long column')) | Out-Null
      $root2 = New-TreeNode @('a second root', 'col 2')
      $root2.AddChild(@('first node on root 2', 'another col on root 2', 'again on root 2')) | Out-Null
      $root2.AddChild(@('node 2 on root 2', '', 'some long column on root 2')) | Out-Null

      # Verify it gets formatted fine
      $tree = @(Get-Tree -Roots @($root1, $root2) -PadColumnsCrossDepth) -Join [Environment]::NewLine
      $tree | Should -Be @"
root 1                  col 2
├─ first node           another col           again
└─ node 2                                     some long column
a second root           col 2
├─ first node on root 2 another col on root 2 again on root 2
└─ node 2 on root 2                           some long column on root 2
"@
    }
  }
}