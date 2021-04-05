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
  # suddenly allow one to build recursive trees. So we are just allowing New-Tree to create roots.
  [TreeNode] AddChild([String[]] $Columns) {
    if ($null -eq $Columns) {
      throw "Columns cannot be null"
    }

    # Create the child node
    $child = [TreeNode]::New($Columns)

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

  # Return the max array from an array of array (of potentially different lengths)
  hidden static [int[]] GetMaxList([int[][]] $List) {
    # Init a max array
    $max = @()

    # Iterate over the first level of the array
    $List | ForEach-Object {
      # Discard bad data
      if (-Not $_) {
        return
      }

      # Get number of elements in current array
      $count = $_.Count

      # Add elements in the max array if needed
      if ($max.Count -lt $count) {
        ($max.Count)..($count - 1) | ForEach-Object { $max += [int]::MinValue }
      }

      # Compute max array
      for ($i = 0; $i -lt $count ; $i++) {
        if ($max[$i] -lt $_[$i]) {
          $max[$i] = $_[$i]
        }
      }
    }

    # Return the max array
    return $max
  }

  hidden static [void] ComputeColumnsMaxLengthPerParent([Hashtable] $ColumnsMaxLengthPerParent, [TreeNode] $Node) {
    # Ignore node with no children (stop recursion)
    if (0 -eq $Node.Children.Count) {
      return
    }

    # Get children columns length array and initiate recursion
    $childrenColumnsMaxLength = @($Node.Children | ForEach-Object {
      ,($_.Columns | ForEach-Object { $_.TextLength })
      [TreeNode]::ComputeColumnsMaxLengthPerParent($ColumnsMaxLengthPerParent, $_)
    })
    if (-not $childrenColumnsMaxLength[0] -is [array]) {
      # Pipes don't preserve int[][] if only one element is returned, fix that here
      $childrenColumnsMaxLength = ,$childrenColumnsMaxLength
    }

    # Compute and store the max length array for the parent
    $ColumnsMaxLengthPerParent[$Node] = [TreeNode]::GetMaxList($childrenColumnsMaxLength)
  }

  # Recursively format the label of every column-based node in the tree
  hidden [void] FormatChildren([int] $SpacesBetweenColumns, [Hashtable] $ColumnsMaxLengthPerParent) {
    # Get the columns max length for the current node
    $columnsMaxLength = $ColumnsMaxLengthPerParent.ContainsKey($this) ? $ColumnsMaxLengthPerParent[$this] : @()

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
      $_.FormatChildren($SpacesBetweenColumns, $ColumnsMaxLengthPerParent)
    }
  }
}