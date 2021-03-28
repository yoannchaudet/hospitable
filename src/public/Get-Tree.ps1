function Get-Tree {
  <#
  .SYNOPSIS
  Format a tree.

  .PARAMETER Roots
  The tree roots to format.

  .PARAMETER SpacesBetweenColumns
  The number of spaces to use to seperate columns in a node.

  .PARAMETER PadColumnsCrossDepth
  By default columns are padded for nodes of the same depth. This switch makes the padding
  apply to all depths.
  #>

  # TODO: Document the prefixes

  param (
    [Object[]] $Roots,
    [String] $TreenInPrefix = (Get-SettingValue 'TREE_IN_PREFIX' '│  '),
    [String] $TreeBranchPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '├─ '),
    [String] $TreeLeafPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '└─ '),
    [int] $SpacesBetweenColumns = 1,
    [switch] $PadColumnsCrossDepth
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
        $Indent += (" " * $TreenInPrefix.Length)
      } else {
        $Indent += $TreenInPrefix
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

  # Utility function for computing a global (cross depth) columns max length array
  function Join-ColumnsMaxLengthCrossDepth() {
    param (
      [Hashtable] $ColumnsMaxLengthPerDepth,
      [int] $IndentationLength
    )

    # Get the max length per column cross all depth
    $maxLengthPerColumn = @()
    $maxDepth = $ColumnsMaxLengthPerDepth.Count
    $ColumnsMaxLengthPerDepth.GetEnumerator() | ForEach-Object {
      $columns = $_.Value
      $columnsCount = $columns.Count

      # Add elements in the array
      if ($maxLengthPerColumn.Count -lt $columnsCount) {
        ($maxLengthPerColumn.Length)..($columnsCount - 1) | ForEach-Object { $maxLengthPerColumn += 0 }
      }

      # Get the max lengths
      0..($columnsCount - 1) | ForEach-Object {
        if ($maxLengthPerColumn[$_] -lt $columns[$_]) {
          $maxLengthPerColumn[$_] = $columns[$_]
        }
      }
    }

    # Update the hashtable
    @($ColumnsMaxLengthPerDepth.Keys) | ForEach-Object {
      $ColumnsMaxLengthPerDepth[$_] = $maxLengthPerColumn.Clone()
      # Accomodate indentation
      $ColumnsMaxLengthPerDepth[$_][0] += ($maxDepth - $_ - 1) * $IndentationLength
    }
  }

  # Format the tree
  $invisibleRoot = New-TreeNode
  $Roots | ForEach-Object { $invisibleRoot.Children.Add($_) }
  $columnsMaxLengthPerDepth = @{}
  $invisibleRoot.ComputeColumnsMaxLengthPerDepth($columnsMaxLengthPerDepth, 0)
  if ($PadColumnsCrossDepth) {
    Join-ColumnsMaxLengthCrossDepth -ColumnsMaxLengthPerDepth $columnsMaxLengthPerDepth -IndentationLength $TreenInPrefix.Length
  }
  $invisibleRoot.FormatChildren($SpacesBetweenColumns, $columnsMaxLengthPerDepth, 0)
  if ($Roots.Count -eq 1) {
    Format-TreeNode -Node $Roots[0] -Indent "" -Last $true -Root $true
  } else {
    Format-TreeChildren -Children $Roots -Indent "" -Root $true
  }
}
