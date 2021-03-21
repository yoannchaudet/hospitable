function Get-FormattedText {
  <#
  .SYNOPSIS
  Apply VT-100 modifiers to a string in order to apply a formatting.

  .PARAMETER Value
  The string to format.

  .PARAMETER PreModifier
  The modifier to add before the value.

  .PARAMETER PostModifier
  The modifier to apply after the value.
  #>

  param (
    [string] $Value,
    [Parameter(Mandatory)]
    [string] $PreModifier,
    [Parameter(Mandatory)]
    [string] $PostModifier
  )

  if ($Value) {
    "$($script:ESC)$($PreModifier)$Value$($script:ESC)$($PostModifier)"
  }

}