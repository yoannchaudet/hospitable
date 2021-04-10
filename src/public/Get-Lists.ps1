function Get-Lists {
  <#
  .SYNOPSIS
  Format a list (of lists).

  .PARAMETER List
  The list (of lists) of objects to format.

  .OUTPUTS
  The formatted string.
  #>

  param (
    [object[]] $Lists
  )

  # Get prefixes
  $listFirstPrefix = Get-SettingValue 'LIST_FIRST_PREFIX' '┌─ '
  $listNPrefix = Get-SettingValue 'LIST_N_PREFIX' '├─ '
  $listLastPrefix = Get-SettingValue 'LIST_LAST_PREFIX' '└─ '
  $listOneItemPrefix = Get-SettingValue 'LIST_ONE_ITEM_PREFIX' ' ─ '

  # Iterate over the lists
  $Lists | Where-Object { $_ } | ForEach-Object {

    # Iterate over the list in the current list
    $list = @($_)
    for ($i = 0; $i -lt $list.Count; $i++) {
      # Select the appropriate prefix
      $prefix = $listNPrefix
      if ($i -eq 0 -and $list.Count -eq 1) {
        $prefix = $listOneItemPrefix
      } elseif ($i -eq 0) {
        $prefix = $listFirstPrefix
      } elseif ($i -eq ($list.Count -1)) {
        $prefix = $listLastPrefix
      }

      # Output the element
      "${prefix}$($list[$i])"
    }
  }
}
