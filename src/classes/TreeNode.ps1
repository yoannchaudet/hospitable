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
  # Text to display in the column
  [String] $Text

  # Text lengh
  [int] $TextLength

  # Column alignment
  [ColumnAlignment] $Alignment

  # Column length (which may include padding)
  [int] $ColumnLength
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

  # Depth at which the tree node lives
  hidden [int] $Depth

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

    # Set depth
    $child.Depth = $this.Depth + 1

    # Add the child node and return it
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

  # Compute the default columns length for the current node and recursively through
  # the tree
  [void] ComputeDefaultColumnsLength() {
    # Stop recursion at leaf nodes
    if (0 -eq $this.Children.Count) {
      return
    }

    # Arrange in a two-dimension array the columns length of the direct children
    $childrenColumnsLength = @()
    $this.Children | ForEach-Object {
      $childrenColumnsLength += ,($_.Columns | ForEach-Object { $_.TextLength })
    }

    # Compute the default columns length and assign it to the children
    $childrenColumnsLength = @(Get-MaxArray $childrenColumnsLength)
    $this.Children | ForEach-Object {
      $cols = $_.Columns
      for ($i = 0; $i -lt [Math]::Min($childrenColumnsLength.Count, $cols.Count); $i++) {
        $cols[$i].ColumnLength = $childrenColumnsLength[$i]
      }
    }

    # Recurse
    $this.Children | ForEach-Object {
      $_.ComputeDefaultColumnsLength()
    }
  }

  ###
  ### Static methods
  ###

  # Recursively format the label of every column-based node in the tree
  hidden [void] FormatChildren([int] $SpacesBetweenColumns) {
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
            $column.Text.PadRight($column.ColumnLength + $invisibleCharacters, ' ')
          }
          'Right' {
            $column.Text.PadLeft($column.ColumnLength + $invisibleCharacters, ' ')
          }
          'Centered' {
            $col = $column.Text
            $col = $col.PadRight(($column.ColumnLength - $column.TextLength) / 2 + $column.TextLength + $invisibleCharacters, ' ')
            $col = $col.PadLeft($column.ColumnLength + $invisibleCharacters, ' ')
            $col
          }
        }
      }) -Join (' ' * $SpacesBetweenColumns)).TrimEnd()
    }

    # Continue recursively
    $this.Children | ForEach-Object {
      $_.FormatChildren($SpacesBetweenColumns)
    }
  }
}