function Get-Tree {
  <#
  .SYNOPSIS
  Format a tree.

  .PARAMETER TreeDSL
  The domain specific language for building the tree.

  .PARAMETER SpacesBetweenColumns
  The number of spaces to use to seperate columns in a node.
  #>

  # TODO: Document the prefixes

  param (
    [Parameter(Mandatory)]
    [scriptblock] $TreeDSL,
    [string] $TreeInPrefix = (Get-SettingValue 'TREE_IN_PREFIX' '│  '),
    [string] $TreeBranchPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '├─ '),
    [string] $TreeLeafPrefix = (Get-SettingValue 'TREE_BRANCH_PREFIX' '└─ '),
    [ValidateRange(0, 42)]
    [int] $SpacesBetweenColumns = 1
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

  # Recursive function for returning all nodes in the tree
  function Get-TreeChildren {
    param (
      [TreeNode] $Node
    )

    # Output the node (ignore the root with no columns)
    if ($Node.Columns.Count -gt 0) {
      $Node
    }

    # Recurse over  the children
    $Node.Children | ForEach-Object { Get-TreeChildren $_ }
  }

  # Validate the prefixes are all of the same length
  $prefixesSameLength = $TreeInPrefix -and $TreeBranchPrefix -and $TreeLeafPrefix
  $prefixesSameLength = $prefixesSameLength -and $TreeInPrefix.Length -eq $TreeBranchPrefix.Length
  $prefixesSameLength = $prefixesSameLength -and $TreeBranchPrefix.Length -eq $TreeLeafPrefix.Length
  if (-not $prefixesSameLength) {
    throw 'Prefixes are either not all provided or of different lengths'
  }

  # Create a tree root
  $root = [TreeNode]::New(@())

  # Context of the tree DSL
  $invokeContext = @{
    # Build a new node
    Node = {
      param (
        [Parameter(Mandatory)]
        [string[]] $Columns,
        [scriptblock] $NodeDSL
      )

      # Add the child to the current node
      $currentNode = $Node.AddChild($Columns)

      # If a DSL scriptblock was passed, invoke it with the new node as the context
      if ($NodeDSL) {
        $NodeDSL.InvokeWithContext($invokeContext, @(New-Variable 'Node' $currentNode))
      }
    }

    # Set alignment group
    AlignmentGroup = {
      param (
        [Parameter(Mandatory)]
        [int] $AlignmentGroup
      )
      $Node.AlignmentGroup = $AlignmentGroup
    }

    # Set children alignment group
    ChildrenAlignmentGroup = {
      param (
        [Parameter(Mandatory)]
        [int] $AlignmentGroup
      )
      $Node.ChildrenAlignmentGroup = $AlignmentGroup
    }

    # Set column alignment
    ColumnAlignment = {
      param (
        [Parameter(Mandatory)]
        [int] $ColumnIndex,
        [Parameter(Mandatory)]
        [ValidateSet('Left', 'Right', 'Centered')]
        [string] $ColumnAlignment
      )
      $Node.SetColumnAlignment($ColumnIndex, $ColumnAlignment)
    }

    # Set children column alignment
    ChildrenColumnAlignment = {
      param (
        [Parameter(Mandatory)]
        [int] $ColumnIndex,
        [Parameter(Mandatory)]
        [ValidateSet('Left', 'Right', 'Centered')]
        [string] $ColumnAlignment
      )
      $Node.SetChildrenColumnAlignment($ColumnIndex, $ColumnAlignment)
    }
  }

  # Invoke the DSL scriptblock with the root as the context
  $TreeDSL.InvokeWithContext($invokeContext, @(New-Variable 'Node' $root))

  #
  # Handle alignment groups
  #

  # Get the prefix length
  $prefixLength = $TreeInPrefix.Length

  # Collect tree nodes per alignment groups
  $nodesPerGroup = @{}
  Get-TreeChildren $root | ForEach-Object {
    if (-Not $nodesPerGroup.ContainsKey($_.AlignmentGroup)) {
      $nodesPerGroup[$_.AlignmentGroup] = @()
    }
    $nodesPerGroup[$_.AlignmentGroup] += $_
  }

  # Align group of nodes
  $nodesPerGroup.Values | ForEach-Object {
    # Get the group of nodes to align
    $group = $_

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
  $root.FormatChildren($SpacesBetweenColumns)
  Format-TreeChildren -Children $root.Children -Indent '' -Root $true
}
