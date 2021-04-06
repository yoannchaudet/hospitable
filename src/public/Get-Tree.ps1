function Get-Tree {
  <#
  .SYNOPSIS
  Format a tree.

  .PARAMETER Root
  The tree root to format.

  .PARAMETER SpacesBetweenColumns
  The number of spaces to use to seperate columns in a node.

  .PARAMETER AlignmentGroups
  The nodes to align together.
  #>

  # TODO: Document the prefixes
  # TODO: handle $root = $null (it fails now), add a test

  param (
    [object] $Root,
    [string] $TreeInPrefix = (Get-SettingValue 'TREE_IN_PREFIX' '│  '),
    [string] $TreeBranchPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '├─ '),
    [string] $TreeLeafPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '└─ '),
    [int] $SpacesBetweenColumns = 1,
    [array] $AlignmentGroups
  )

  # Recursive function for formatting a tree node
  function Format-TreeNode {
    param (
      [TreeNode] $Node,
      [String] $Indent,
      [Boolean] $Last,
      [Boolean] $Root
    )

    # Print node prefix + name
    $outputPrefix = ""
    if (!$Root) {
      $outputPrefix += $Indent
      $outputPrefix += ($Last ? $TreeLeafPrefix : $TreeBranchPrefix)
    }
    "${outputPrefix}$($Node.Label)"

    # Recursively increment the indentation
    if (!$Root) {
      if ($Last) {
        $Indent += (" " * $TreeInPrefix.Length)
      } else {
        $Indent += $TreeInPrefix
      }
    }

    # Render children
    Format-TreeChildren -Children $Node.Children -Indent $Indent
  }

  # Utility function for rendering the children of a tree node
  function Format-TreeChildren {
    param (
      [TreeNode[]] $Children,
      [String] $Indent,
      [Boolean] $Root
    )

    # Render all children
    for ($i = 0; $i -lt $Children.Count; $i++) {
      Format-TreeNode `
        -Node $Children[$i] `
        -Indent $Indent `
        -Last ($i -eq $Children.Count -1) `
        -Root $Root
    }
  }

  # Compute default columns length
  $Root.ComputeDefaultColumnsLength()

  # Handle alignment groups
  if ($AlignmentGroups) {
    ConvertTo-TwoDimensionsArray ([ref] $AlignmentGroups)
    $AlignmentGroups | ForEach-Object {
      # Get the group of nodes to align
      $group = $_

      # Get the maximum depth
      $maxDepth = ($_ | ForEach-Object { $_.Depth } | Measure-Object -Maximum).Maximum

      # Arrange in a two-dimension array the columns length of the nodes in the group
      $groupColumnsLength = @()
      $group | ForEach-Object {
        $groupColumnsLength += ,($_.Columns | ForEach-Object { $_.TextLength })
      }

      # Compute the columns length and assign it to the nodes in the group
      $groupColumnsLength = @(Get-MaxArray $groupColumnsLength)
      $_ | ForEach-Object {
        $cols = $_.Columns
        for ($i = 0; $i -lt [Math]::Min($groupColumnsLength.Count, $cols.Count); $i++) {
          $cols[$i].ColumnLength = $groupColumnsLength[$i]
        }
      }

      # Fix the first column length to adjust for the prefix
      $_ | Where-Object { $_.Depth -lt $maxDepth } | ForEach-Object {
        $depthDelta = $maxDepth - $_.Depth
        $_.Columns[0].ColumnLength += ($depthDelta * 3)
      }
    }
  }

  # Format the tree
  $Root.FormatChildren($SpacesBetweenColumns)
  Format-TreeChildren -Children $Root.Children -Indent '' -Root $true
}
