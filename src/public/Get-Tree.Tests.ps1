# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-Tree' {
    It 'Formats one-node tree' {
      # Create a tree
      $tree = New-Tree
      $root = $tree.AddChild('root')
      $node1 = $root.AddChild('node1')
      $node1.AddChild('subnode 1') | Out-Null
      $node1.AddChild('subnode 2') | Out-Null
      $root.AddChild('node2' ) | Out-Null

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
      $node0.AddChild('subnode 1') | Out-Null
      $node0.AddChild('subnode 2') | Out-Null
      $tree.AddChild('node 1') | Out-Null

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
      $root.SetColumnAlignment(0, 'Right')
      $root.SetColumnAlignment(1, 'Centered')
      $root.AddChild(@('col1', 'col2', 'col3'))
      $root.AddChild('some text')
      $lastNode = $root.AddChild(@('1', '2', '3'))
      $lastNode.SetColumnAlignment(0, 'Left') # test overwrite

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
      $node1 = $tree.AddChild('French')
      $node2 = $tree.AddChild('Spanish')
      $bonjour = $node1.AddChild(('bonjour', 'hello'))
      $hola = $node2.AddChild(('hola', 'hello'))

      # Regular formatting
      $out = @(Get-Tree $tree) -Join [Environment]::NewLine
      $out | Should -Be @"
French
└─ bonjour hello
Spanish
└─ hola hello
"@

      # With alignment groups
      $out = @(Get-Tree $tree -AlignmentGroups ($bonjour, $hola)) -Join [Environment]::NewLine
      $out | Should -Be @"
French
└─ bonjour hello
Spanish
└─ hola    hello
"@

      # With proper alignment groups
      $out = @(Get-Tree $tree -AlignmentGroups (,($node1, $node2))) -Join [Environment]::NewLine
      $out | Should -Be @"
French
└─ bonjour hello
Spanish
└─ hola    hello
"@
    }
  }
}