# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'Get-FormattedText' {
    It 'Ignores null or empty strings' {
      Get-FormattedText -Value $null -PreModifier 'pre' -PostModifier 'post' | Should -BeNullOrEmpty
      Get-FormattedText -Value '' -PreModifier 'pre' -PostModifier 'post' | Should -BeNullOrEmpty
      Get-FormattedText -PreModifier 'pre' -PostModifier 'post' | Should -BeNullOrEmpty
    }

    It 'Formats text' {
      Get-FormattedText -Value 'value' -PreModifier 'pre' -PostModifier 'post' -Esc '!' | Should -Be '!prevalue!post'
      Get-FormattedText -Value "value`nvalue" -PreModifier 'pre' -PostModifier 'post' -Esc '!' | Should -Be "!prevalue`nvalue!post"
    }
  }

  Describe 'Get-Bold' {
    It 'Ignores null or empty strings' {
      Get-Bold -Value $null | Should -BeNullOrEmpty
      Get-Bold -Value '' | Should -BeNullOrEmpty
      Get-Bold | Should -BeNullOrEmpty
    }

    It 'Formats text' {
      Get-Bold 'bold' | Should -Be "$($script:ESC)$($script:TEXT_BOLD)bold$($script:ESC)$($script:TEXT_NO_BOLD)"
    }
  }

  Describe 'Get-Negative' {
    It 'Ignores null or empty strings' {
      Get-Negative -Value $null | Should -BeNullOrEmpty
      Get-Negative -Value '' | Should -BeNullOrEmpty
      Get-Negative | Should -BeNullOrEmpty
    }

    It 'Formats text' {
      Get-Negative 'negative' | Should -Be "$($script:ESC)$($script:TEXT_NEGATIVE)negative$($script:ESC)$($script:TEXT_NO_NEGATIVE)"
    }
  }

  Describe 'Get-Underline' {
    It 'Ignores null or empty strings' {
      Get-Underline -Value $null | Should -BeNullOrEmpty
      Get-Underline -Value '' | Should -BeNullOrEmpty
      Get-Underline | Should -BeNullOrEmpty
    }

    It 'Formats text' {
      Get-Underline 'underline' | Should -Be "$($script:ESC)$($script:TEXT_UNDERLINE)underline$($script:ESC)$($script:TEXT_NO_UNDERLINE)"
    }
  }

  Describe 'Get-FormattedStringLength' {
    It 'Supports null and empty strings' {
      Get-FormattedStringLength | Should -Be 0
      Get-FormattedStringLength '' | Should -Be 0
    }

    It 'Supports strings not containing modifiers' {
      Get-FormattedStringLength 'a' | Should -Be 1
      Get-FormattedStringLength 'hello' | Should -Be 5
      Get-FormattedStringLength 'hello 🤠' | Should -Be 'hello 🤠'.Length
      Get-FormattedStringLength "  `nline 1`nlines 2 " | Should -Be "  `nline 1`nlines 2 ".Length
    }

    It 'Supports valid text formatting' {
      Get-FormattedStringLength (Get-Bold 'hello') | Should -Be 5
      Get-FormattedStringLength ('hello 🤠' | Get-Bold | Get-Underline) | Should -Be 'hello 🤠'.Length
      Get-FormattedStringLength ("  `nline 1`nlines 2 " | Get-Bold | Get-Underline | Get-Negative) | Should -Be "  `nline 1`nlines 2 ".Length
      Get-FormattedStringLength @('a', (Get-Bold 'b'), (Get-Negative 'c'), (Get-Underline 'd')) -Join ' ' | Should -Be 7
    }
  }
}