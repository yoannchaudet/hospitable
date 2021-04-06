###
### Utilities functions
###

function ConvertTo-TwoDimensionsArray {
  <#
  .SYNOPSIS
  Convert an array into a two-dimension array if it is not the case already.

  .PARAMETER ArrayRef
  A reference to the array to convert.
  #>

  param (
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [ref] $ArrayRef
  )

  # Validate the value type
  if ($ArrayRef.Value -isnot [array]) {
    throw 'Reference was not an array'
  }


  if ($ArrayRef.Value.Count -eq 0 -or $ArrayRef.Value[0] -isnot [array]) {
    $ArrayRef.Value = ,$ArrayRef.Value
  }

}

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