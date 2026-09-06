$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
foreach ($file in (Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1')) {
 $parseErrors = $null
 $tokens = $null
 [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
 if ($parseErrors) { throw ($parseErrors | Out-String) }
}
Write-Output 'PowerShell syntax passed.'
