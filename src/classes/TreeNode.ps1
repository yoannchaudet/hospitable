###
### Object representing a tree node.
###
### A tree node has a set of columns to display on one line (formatted as a label).
### Columns can have an alignment (left, centered or right).
### Finally, a tree node may have children.
###

class TreeNode {
  ###
  ### Properties
  ###

  # Label to display
  hidden [String] $Label

  # Columns (instead of a single label)
  [String[]] $Columns

  # Columns alignment (index -> 'left|right|centered')
  hidden [Hashtable] $ColumnsAlignment

  # List of children for this node
  [System.Collections.Generic.List[TreeNode]] $Children

  ###
  ### Constructor
  ###

  # Build a new tree node
  TreeNode([String[]] $Columns) {
    # Get number of columns passed
    $columnsCount = $Columns ? $Columns.Count : 0

    # Init properties
    $this.Label            = $columnsCount -eq 1 ? $Columns[0] : ""
    $this.Columns          = $columnsCount -lt 1 ? @() : $Columns
    $this.ColumnsAlignment = @{}
    $this.Children         = New-Object 'System.Collections.Generic.List[TreeNode]'
  }

  ###
  ### Methods
  ###

  # Add a new child to the current node and return it
  # Note: we could have introduced a version accepting a TreeNode object too but that would
  # suddenly allow one to build recursive trees. So we are just allowing New-TreeNode to create roots.
  [TreeNode] AddChild([String[]] $Columns) {
    $child = [TreeNode]::New($Columns)
    $this.Children.Add($child)
    return $child
  }

  # Set column alignment (left, right, centered) for a given column index (starting at 0)
  [void] SetColumnAlignment([int] $ColumnIndex, [string] $Alignment) {
    # If an alignment is provided, set it
    if ($Alignment) {
      $this.ColumnsAlignment[$ColumnIndex] = $Alignment
    }

    # Or clear it
    else {
      $this.ColumnsAlignment.Remove($ColumnIndex)
    }
  }

  # Recursively compute the max length of each columns (per depth)
  hidden [void] ComputeColumnsMaxLengthPerDepth([Hashtable] $ColumnsMaxLengthPerDepth, [int] $Depth) {
    # Compute the column max lengths for the current children
    $this.Children | Where-Object { $_.Columns.Count -gt 0 } | ForEach-Object {
      # Get the columns count for the child
      $columnsCount = $_.Columns.Count

      # Get the columns max length array for the current depth (create it if needed)
      $columnsMaxLength = $ColumnsMaxLengthPerDepth.ContainsKey($Depth) ? $ColumnsMaxLengthPerDepth[$Depth] : @()

      # Add elements in the array
      if ($columnsMaxLength.Count -lt $columnsCount) {
        ($columnsMaxLength.Length)..($columnsCount - 1) | ForEach-Object { $columnsMaxLength += 0 }
      }

      # Compute max individual column length
      for ($i = 0; $i -lt $columnsCount ; $i++) {
        if ($columnsMaxLength[$i] -lt $_.Columns[$i].Length) {
          $columnsMaxLength[$i] = $_.Columns[$i].Length
        }
      }

      # Store the array back in the hashtable
      $ColumnsMaxLengthPerDepth[$Depth] = $columnsMaxLength
    }

    # Continue recursively
    $this.Children | ForEach-Object {
      $_.ComputeColumnsMaxLengthPerDepth($ColumnsMaxLengthPerDepth, $Depth + 1)
    }
  }

  # Recursively format the label of every column-based node in the tree
  hidden [void] FormatChildren([int] $SpacesBetweenColumns, [Hashtable] $ColumnsMaxLengthPerDepth, [int] $Depth) {
    # Get the columns max length for this depth
    $columnsMaxLength = $ColumnsMaxLengthPerDepth.ContainsKey($Depth) ? $ColumnsMaxLengthPerDepth[$Depth] : @()

    # Format the children that have columns
    $this.Children | Where-Object { $_.Columns.Count -gt 0 } | ForEach-Object {
      $node = $_
      $node.Label = (@(0..($node.Columns.Count - 1) | ForEach-Object {
        $columnIndex = $_

        # Get column alignment
        $columnAlignment = $null
        if ($this.ColumnsAlignment -and $this.ColumnsAlignment.ContainsKey($columnIndex)) {
          $columnAlignment = $this.ColumnsAlignment[$columnIndex]
        }
        if (!($columnAlignment -imatch 'left|right|centered')) {
          $columnAlignment = 'left'
        }

        # Pad the column
        switch ($columnAlignment) {
          'left' {
            $node.Columns[$columnIndex].PadRight($columnsMaxLength[$columnIndex], ' ')
          }
          'right' {
            $node.Columns[$columnIndex].PadLeft($columnsMaxLength[$columnIndex], ' ')
          }
          'centered' {
            $col = $node.Columns[$columnIndex]
            $col = $col.PadRight(($columnsMaxLength[$columnIndex] - $col.Length) / 2 + $col.Length, ' ')
            $col = $col.PadLeft($columnsMaxLength[$columnIndex], ' ')
            $col
          }
        }
      }) -Join (' ' * $SpacesBetweenColumns)).TrimEnd()
    }

    # Continue recursively
    $this.Children | ForEach-Object {
      $_.FormatChildren($SpacesBetweenColumns, $ColumnsMaxLengthPerDepth, $Depth + 1)
    }
  }
}