###
### Everything to represent tree nodes
###

enum ColumnAlignment {
  Default
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
    $columnsCount = $null -ne $Columns ? $Columns.Count : 0
    $this.Columns = $columnsCount -lt 1 ? @() : ($Columns | ForEach-Object {
      $trimmedText = $_.Trim()
      [TreeNodeColumn] @{
        Text = $trimmedText
        TextLength = Get-FormattedStringLength $trimmedText
        Alignment = [ColumnAlignment]::Default
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
    if ($Columns -eq $null) {
      throw "Columns cannot be null"
    }

    # Create the child node
    $child = New-TreeNode $Columns

    # Inherit the column alignment from the parent
    for ($i = 0; $i -lt [Math]::Min($Columns.Count, $this.Columns.Count); $i++) {
      $child.SetColumnAlignment($i, $this.Columns[$i].Alignment)
    }

    # Ad the child node and return it
    $this.Children.Add($child)
    return $child
  }

  # Set column alignment for a given column
  # Note: when alignment is set for a given node, children will inherit the same alignment by default unless overwritten
  [void] SetColumnAlignment([int] $ColumnIndex, [ColumnAlignment] $Alignment) {
    # Ignore negative index
    if ($ColumnIndex -lt 0) {
      return
    }

    # If the index is out of bound, create new empty columns
    while ($ColumnIndex -ge $this.Columns.Count) {
      $this.Columns += [TreeNodeColumn] @{
        Text = ''
        TextLength = 0
        Alignment = [ColumnAlignment]::Default
      }
    }

    # Set the alignment
    $this.Columns[$ColumnIndex].Alignment = $Alignment
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
          { $_ -in 'Default', 'Left' } {
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