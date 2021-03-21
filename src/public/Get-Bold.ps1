﻿function Get-Bold {
  <#
  .SYNOPSIS
  Apply VT-100 modifiers to a string to format it in bold.

  .PARAMETER Value
  The string to format.
  #>

  param (
    [Parameter(ValueFromPipeline = $true)]
    [string] $Value
  )

  process {
    Get-FormattedText `
      -Value $Value `
      -PreModifier $script:TEXT_BOLD `
      -PostModifier $script:TEXT_NO_BOLD
  }
}