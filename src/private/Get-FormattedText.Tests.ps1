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
      Get-FormattedText -Value 'value' -PreModifier 'pre' -PostModifier 'post' | Should -Be 'prevaluepost'
      Get-FormattedText -Value "value`nvalue" -PreModifier 'pre' -PostModifier 'post' | Should -Be "prevalue`nvaluepost"
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
}