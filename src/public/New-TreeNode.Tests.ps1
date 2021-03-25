﻿# Load (or reload) the module
Remove-Module -Name 'Hospitable' -Force -ErrorAction 'SilentlyContinue'
Import-Module (Join-Path $PSScriptRoot '../Hospitable.psm1')

InModuleScope Hospitable {
  Describe 'New-TreeNode' {
    It 'Creates empty tree node' {
      $node = New-TreeNode
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 0
      $node.Children.Count | Should -Be 0
    }

    It 'Creates one-column tree node' {
      $node = New-TreeNode 'label'
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 1
      $node.Children.Count | Should -Be 0
    }

    It 'Creates n-column tree node' {
      $node = New-TreeNode 'col1', ('col2' | Get-Bold)
      $node.Label | Should -Be ''
      $node.Columns.Count | Should -Be 2
      $node.Columns[0].Text | Should -Be 'col1'
      $node.Columns[0].TextLength | Should -Be 4
      $node.Columns[0].Alignment | Should -Be 'Left'
      $node.Columns[1].Text | Should -Be ('col2' | Get-Bold)
      $node.Columns[1].TextLength | Should -Be (Get-FormattedStringLength ('col2' | Get-Bold))
      $node.Columns[1].Alignment | Should -Be 'Left'
      $node.Children.Count | Should -Be 0
    }
  }
}