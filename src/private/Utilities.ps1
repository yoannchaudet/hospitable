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