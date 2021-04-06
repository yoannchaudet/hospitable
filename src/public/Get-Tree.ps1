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

  # Compute the max length array for each parent
  $columnsMaxLengthPerParent = @{}
  [TreeNode]::ComputeColumnsMaxLengthPerParent($columnsMaxLengthPerParent, $Root)

  # Handle alignment groups
  if ($AlignmentGroups) {
    ConvertTo-TwoDimensionsArray ([ref] $AlignmentGroups)
    $AlignmentGroups | ForEach-Object {
      $lengthPerAlignmentGroup = $_ | ForEach-Object { ,$columnsMaxLengthPerParent[$_] }
      ConvertTo-TwoDimensionsArray ([ref] $lengthPerAlignmentGroup)
      $maxLength = [TreeNode]::GetMaxList($lengthPerAlignmentGroup)
      $_ | ForEach-Object { $columnsMaxLengthPerParent[$_] = $maxLength }
    }
  }

  # Format the tree
  $Root.FormatChildren($SpacesBetweenColumns, $columnsMaxLengthPerParent)
  Format-TreeChildren -Children $Root.Children -Indent '' -Root $true
}
