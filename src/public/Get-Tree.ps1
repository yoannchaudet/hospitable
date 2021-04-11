function Get-Tree {
  <#
  .SYNOPSIS
  Format a tree.

  .PARAMETER Root
  The tree root to format.

  .PARAMETER SpacesBetweenColumns
  The number of spaces to use to seperate columns in a node.

  .PARAMETER AlignmentGroups
  The nodes to align together as a two-dimension array. Note: invalid values are silently ignored.
  #>

  # TODO: Document the prefixes

  param (
    [Parameter(Mandatory)]
    [object] $Root,
    [string] $TreeInPrefix = (Get-SettingValue 'TREE_IN_PREFIX' '│  '),
    [string] $TreeBranchPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '├─ '),
    [string] $TreeLeafPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '└─ '),
    [ValidateRange(0, 42)]
    [int] $SpacesBetweenColumns = 1,
    [object[][]] $AlignmentGroups
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

  # Make sure the root is of the correct type
  if ($Root -isnot [TreeNode]) {
    throw 'Root is invalid'
  }

  # Validate the prefixes are all of the same length
  $prefixesSameLength = $TreeInPrefix -and $TreeBranchPrefix -and $TreeLeafPrefix
  $prefixesSameLength = $prefixesSameLength -and $TreeInPrefix.Length -eq $TreeBranchPrefix.Length
  $prefixesSameLength = $prefixesSameLength -and $TreeBranchPrefix.Length -eq $TreeLeafPrefix.Length
  if (-not $prefixesSameLength) {
    throw 'Prefixes are either not all provided or of different lengths'
  }

  # Compute default columns length
  $Root.ComputeDefaultColumnsLength()

  # Handle alignment groups (ignore null values)
  @($AlignmentGroups) | Where-Object { $_ } | ForEach-Object {
    # Get the group of nodes to align
    $group = @($_ | Where-Object { $_ -is [TreeNode] })

    # Get the prefix length
    $prefixLength = $TreeInPrefix.Length

    # Arrange in a two-dimension array the columns length of the nodes in the group
    $groupColumnsLength = @()
    $group | ForEach-Object {
      $node = $_
      $groupColumnsLength += ,@((0..($node.Columns.Count - 1)) | ForEach-Object {
        if (0 -eq $_) {
          # Include the prefix length in the column length calculation
          $node.Columns[$_].TextLength + ($node.Depth - 1) * $prefixLength
        } else {
          $node.Columns[$_].TextLength
        }
      })
    }

    # Compute the columns length and assign it to the nodes in the group
    $groupColumnsLength = @(Get-MaxArray $groupColumnsLength)
    $group | ForEach-Object {
      $cols = $_.Columns
      for ($i = 0; $i -lt [Math]::Min($groupColumnsLength.Count, $cols.Count); $i++) {
        $cols[$i].ColumnLength = $groupColumnsLength[$i]
      }
    }

    # Fix the first column length to adjust for the ßprefix
    $group | ForEach-Object {
      $_.Columns[0].ColumnLength -= ($_.Depth - 1) * $prefixLength
    }
  }

  # Format the tree
  $Root.FormatChildren($SpacesBetweenColumns)
  Format-TreeChildren -Children $Root.Children -Indent '' -Root $true
}
