###
### File dot sourced in every tests, responsible for loading the module
###

# Remove all potentially currently loaded modules
Get-Module -Name 'Hospitable' | Remove-Module -Force

# Import the module
if ($env:HOSPITABLE_TEST_RELEASE) {
  # Import from installed location (used to test the module prior to publishing it)
  Import-Module 'Hospitable'
} else {
  Import-Module (Join-Path $PSScriptRoot 'Hospitable.psm1')
}