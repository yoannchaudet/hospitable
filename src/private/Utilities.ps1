###
### Utilities functions
###

function Get-MaxArray {
  <#
  .SYNOPSIS
  Return the max array of a two-dimension array (of potentially different lengths).

  .PARAMETER TwoDimensionsArray
  The two-dimension array from which to compute the max array.

  .OUTPUTS
  The max array.
  #>

  param (
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [int[][]] $TwoDimensionsArray
  )

  # Init a max array
  $max = @()

  # Iterate over the first level of the array
  $TwoDimensionsArray | ForEach-Object {
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
  $max
}

function Confirm-ValidPrefixes {
  <#
  .SYNOPSIS
  Valid that an array of prefixes is valid.

  .PARAMETER Prefixes
  The prefixes to validate.

  .PARAMETER PrefixesCount
  The number of prefixes the array should contain. Throw an exception when false.

  .PARAMETER SameLength
  Switch indicating all prefixes must have the same (non-0) length.

  .OUTPUTS
  When the SameLength switch is set, if the prefixes array is valid, returns the common length of the prefixes in the array.
  #>

  param (
    [AllowEmptyCollection()]
    [string[]] $Prefixes,
    [Parameter(Mandatory)]
    [int] $PrefixesCount,
    [switch] $SameLength
  )

  # Validate prefixes count
  $invalidPrefixes = $null -eq $Prefixes
  $invalidPrefixes = $invalidPrefixes -or @($Prefixes | Where-Object { $_ }).Count -ne @($Prefixes).Count
  $invalidPrefixes = $invalidPrefixes -or @($Prefixes).Count -ne $PrefixesCount
  if ($invalidPrefixes) {
    throw "Invalid number of prefixes provided (expected = $PrefixesCount)"
  }

  # Validate prefixes are all of the same length
  if ($SameLength) {
    $prefixesLength = @($Prefixes | Where-Object { $_ } | ForEach-Object { $_.Length } | Select-Object -Unique)
    if ($prefixesLength.Count -gt 1) {
      throw "Prefixes must all have the same length"
    }

    # Return the prefixes length
    else {
      $prefixesLength[0]
    }
  }
}