function New-Tree {
  <#
  .SYNOPSIS
  Create and return a new tree node (to use as a root).

  .OUTPUTS
  The tree node object.
  #>

  # Return a new tree node
  [TreeNode]::New(@())

}