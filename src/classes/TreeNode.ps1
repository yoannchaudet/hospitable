###
### Everything to represent tree nodes
###

enum ColumnAlignment {
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

  # Children column alignment
  [ColumnAlignment] $ChildrenAlignment

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

  # Alignment group for the tree node
  hidden [int] $AlignmentGroup

  # Alignment group for the children
  hidden [int] $ChildrenAlignmentGroup

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
        Alignment = [ColumnAlignment]::Left
        ChildrenAlignment = [ColumnAlignment]::Left
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
      $child.SetColumnAlignment($i, $this.Columns[$i].ChildrenAlignment)
    }

    # Inherit alignment group
    $child.AlignmentGroup = $this.ChildrenAlignmentGroup

    # Set depth
    $child.Depth = $this.Depth + 1

    # Add the child node and return it
    $this.Children.Add($child)
    return $child
  }

  # Create a column if needed for a given index
  hidden [void] EnsureColumn([int] $ColumnIndex) {
    # If the index is out of bound, create new empty columns
    while ($ColumnIndex -ge $this.Columns.Count) {
      $this.Columns += [TreeNodeColumn] @{
        Text = ''
        TextLength = 0
        Alignment = [ColumnAlignment]::Left
        ChildrenAlignment = [ColumnAlignment]::Left
      }
    }
  }

  # Set column alignment for a given column
  [void] SetColumnAlignment([int] $ColumnIndex, [ColumnAlignment] $Alignment) {
    # Ignore negative index
    if ($ColumnIndex -lt 0) {
      return
    }

    # Set the alignment
    $this.EnsureColumn($ColumnIndex)
    $this.Columns[$ColumnIndex].Alignment = $Alignment
  }

  # Set children column alignment for a given column (i.e. this is the alignment that is inherited for children)
  [void] SetChildrenColumnAlignment([int] $ColumnIndex, [ColumnAlignment] $Alignment) {
    # Ignore negative index
    if ($ColumnIndex -lt 0) {
      return
    }

    # Set the alignment
    $this.EnsureColumn($ColumnIndex)
    $this.Columns[$ColumnIndex].ChildrenAlignment = $Alignment
  }

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
          'Left' {
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