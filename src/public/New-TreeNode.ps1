function New-TreeNode {
  <#
  .SYNOPSIS
  Create and return a new tree node (to use as a root).

  .PARAMETER Columns
  The columns to display in the tree node.

  .OUTPUTS
  The tree node object.
  #>

  param (
    [string[]] $Columns
  )

  # Return a new tree node
  [TreeNode]::New($Columns)

}