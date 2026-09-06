param([string]$Destination)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$engine=Join-Path $project 'runtime\luanti-5.17.0-win64'
$exe=Join-Path $engine 'bin\luanti.exe'
$running = Get-Process -Name luanti -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($running) { throw 'Exit this game before creating a consistent save backup.' }
$worlds=Join-Path $engine 'worlds'
if (-not (Get-ChildItem -LiteralPath $worlds -Directory -ErrorAction SilentlyContinue)) { return }
$backups=Join-Path $project 'backups'
New-Item -ItemType Directory -Force -Path $backups | Out-Null
if (-not $Destination) { $Destination=Join-Path $backups ('worlds-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.zip') }
$partial=$Destination + '.partial.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($worlds,$partial,[IO.Compression.CompressionLevel]::Optimal,$false)
$zip=[IO.Compression.ZipFile]::OpenRead($partial)
try { if ($zip.Entries.Count -lt 1) { throw 'Empty backup.' } } finally { $zip.Dispose() }
Move-Item -LiteralPath $partial -Destination $Destination
Write-Output "Backup: $Destination"
