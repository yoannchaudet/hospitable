###
### Module variables (used as constants)
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