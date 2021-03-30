function Get-Lists {
  <#
  .SYNOPSIS
  Format a list (of lists).

  .PARAMETER List
  The list (of lists) of objects to format.

  .OUTPUTS
  The formatted string.
  #>

  # TODO: Document the prefixes

  param (
    [object[]] $Lists,
    [String] $ListFirstPrefix = (Get-SettingValue 'LIST_FIRST_PREFIX' '┌─ '),
    [String] $ListNPrefix = (Get-SettingValue 'LIST_N_PREFIX' '├─ '),
    [String] $ListLastPrefix = (Get-SettingValue 'LIST_LAST_PREFIX' '└─ '),
    [String] $ListOneItemPrefix = (Get-SettingValue 'LIST_ONE_ITEM_PREFIX' ' ─ ')
  )

  process {
    # Iterate over the lists
    $Lists | ForEach-Object {
      # Ignore empty lists
      if (-Not $_) {
        return
      }

      # Iterate over the list in the current list
      $list = @($_)
      for ($i = 0; $i -lt $list.Count; $i++) {
        # Select the appropriate prefix
        $prefix = $ListNPrefix
        if ($i -eq 0 -and $list.Count -eq 1) {
          $prefix = $ListOneItemPrefix
        } elseif ($i -eq 0) {
          $prefix = $ListFirstPrefix
        } elseif ($i -eq ($list.Count -1)) {
          $prefix = $ListLastPrefix
        }

        # Output the element
        "${prefix}$($list[$i])"
      }
    }
  }
}
