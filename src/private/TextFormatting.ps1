###
### Text formatting utility functions
###

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

  .PARAMETER Esc
  The escape sequence.
  #>

  param (
    [string] $Value,
    [Parameter(Mandatory)]
    [string] $PreModifier,
    [Parameter(Mandatory)]
    [string] $PostModifier,
    [string] $Esc = $script:ESC
  )

  if ($Value) {
    "$($Esc)$($PreModifier)$Value$($Esc)$($PostModifier)"
  }

}