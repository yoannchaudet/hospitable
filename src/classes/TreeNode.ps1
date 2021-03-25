###
### Object representing a tree node.
###
### A tree node has a set of columns to display on one line (formatted as a label).
### Columns can have an alignment (left, centered or right).
### Finally, a tree node may have children.
###

enum ColumnAlignment {
  Left
  Right
  Centered
}

class TreeNodeColumn {
  [String] $Text
  [int] $TextLength
  [ColumnAlignment] $Alignment
}

class TreeNode {

  ###
  ### Properties
  ###

  # Columns
  [TreeNodeColumn[]] $Columns

  # Label to display (i.e. columns formatted one a single line)
  hidden [String] $Label

  # List of children for this node
  hidden [System.Collections.Generic.List[TreeNode]] $Children

  ###
  ### Constructor
  ###

  # Build a new tree node
  TreeNode([String[]] $Columns) {
    # Init properties
    $columnsCount = $Columns ? $Columns.Count : 0
    $this.Columns = $columnsCount -lt 1 ? @() : ($Columns | ForEach-Object {
      $trimmedText = $_.Trim()
      [TreeNodeColumn] @{
        Text = $trimmedText
        TextLength = Get-FormattedStringLength $trimmedText
        Alignment = [ColumnAlignment]::Left
      }
    })
    $this.Label = ''
    $this.Children = New-Object 'System.Collections.Generic.List[TreeNode]'
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

  # Set column alignment for a given column
  [void] SetColumnAlignment([int] $ColumnIndex, [ColumnAlignment] $Alignment) {
    if ($ColumnIndex -ge 0 -and $ColumnIndex -lt $this.Columns.Count) {
      $this.Columns[$ColumnIndex].Alignment = $Alignment
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
        if ($columnsMaxLength[$i] -lt $_.Columns[$i].TextLength) {
          $columnsMaxLength[$i] = $_.Columns[$i].TextLength
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
        $column = $node.Columns[$columnIndex]

        # Pad the column
        $invisibleCharacters = $column.Text.Length - $column.TextLength
        switch ($column.Alignment) {
          'Left' {
            $column.Text.PadRight($columnsMaxLength[$columnIndex] + $invisibleCharacters, ' ')
          }
          'Right' {
            $column.Text.PadLeft($columnsMaxLength[$columnIndex] + $invisibleCharacters, ' ')
          }
          'Centered' {
            $col = $column.Text
            $col = $col.PadRight(($columnsMaxLength[$columnIndex] - $column.TextLength) / 2 + $column.TextLength + $invisibleCharacters, ' ')
            $col = $col.PadLeft($columnsMaxLength[$columnIndex] + $invisibleCharacters, ' ')
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