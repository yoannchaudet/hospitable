function Get-Lists {
  <#
  .SYNOPSIS
  Format a list (of lists).

  .PARAMETER List
  The list (of lists) of objects to format.

  .PARAMETER Prefixes
  A 4-element array containing the prefixes to use for formatting the list.

  .OUTPUTS
  The formatted string.
  #>

  param (
    [object[]] $Lists,
    [string[]] $Prefixes = @(
      (Get-SettingValue 'LIST_FIRST_PREFIX' '┌─ '),
      (Get-SettingValue 'LIST_N_PREFIX' '├─ '),
      (Get-SettingValue 'LIST_LAST_PREFIX' '└─ '),
      (Get-SettingValue 'LIST_ONE_ITEM_PREFIX' ' ─ ')
    )
  )

  # Validate the prefixes
  Confirm-ValidPrefixes $Prefixes -PrefixesCount 4

  # Iterate over the lists
  $Lists | Where-Object { $_ } | ForEach-Object {
    # Iterate over the list of list (or singleton)
    $list = @($_)
    for ($i = 0; $i -lt $list.Count; $i++) {
      # Select the appropriate prefix
      $prefix = $Prefixes[1]
      if ($i -eq 0 -and $list.Count -eq 1) {
        $prefix = $Prefixes[3]
      } elseif ($i -eq 0) {
        $prefix = $Prefixes[0]
      } elseif ($i -eq ($list.Count -1)) {
        $prefix = $Prefixes[2]
      }

      # Output the element
      "${prefix}$($list[$i])"
    }
  }
}
