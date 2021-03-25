###
### Module variables (used as constants) and utilities
###

# VT-100 text formatting
# See https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences#text-formatting
$script:ESC = "$([char]27)"
$script:TEXT_BOLD = "[1m"
$script:TEXT_NO_BOLD = "[22m"
$script:TEXT_UNDERLINE = "[4m"
$script:TEXT_NO_UNDERLINE = "[24m"
$script:TEXT_NEGATIVE = "[7m"
$script:TEXT_NO_NEGATIVE = "[27m"

function Get-SettingValue {
  <#
  .SYNOPSIS
  Return a setting value that may have an override.

  .PARAMETER Setting
  The setting name.

  .PARAMETER DefaultValue
  The default value (when no override has been defined).

  .OUTPUTS
  The setting value as a string.
  #>

  param (
    [Parameter(Mandatory)]
    [string] $Setting,
    [Parameter(Mandatory)]
    [string] $DefaultValue
  )

  # Try to get a globlal override
  $override = [string](Get-Variable `
    -Name "HOSPITABLE_$Setting" `
    -Scope 'global' `
    -ValueOnly `
    -ErrorAction SilentlyContinue)

  # Return the override if it was defined or the default value
  $override ? $override : $DefaultValue

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