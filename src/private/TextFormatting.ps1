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

function Get-FormattedStringLength {
  <#
  .SYNOPSIS
  Return the length of a string excluding VT-100 text formatting modifiers.

  .PARAMETER FormattedString
  The formatted string for which to return the length.

  .OUTPUTS
  The string length.
  #>

  param (
    [string] $FormattedString
  )

  # Handle null input
  if (-Not $FormattedString) {
    return 0
  }

  # Get the length of all text formatting modifiers
  $modifiersLength = [Regex]::Matches($FormattedString, "$($script:ESC)\[[0-9]+m") | ForEach-Object {
    $_.Groups[0].Length
  } | Measure-Object -Sum

  # Return the total length minus the modifiers
  $FormattedString.Length - $modifiersLength.Sum
}