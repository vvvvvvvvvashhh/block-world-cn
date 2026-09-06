param()
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $project 'runtime\luanti-5.17.0-win64'
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force -Path (Join-Path $project 'evidence') | Out-Null
$lines = @("[$(Get-Date -Format s)] Offline setup")

function Restore-BundledTree {
 param([string]$Archive, [string]$Sha256, [string]$Top, [string]$Destination)
 $zip = Join-Path $project ('downloads\' + $Archive)
 if (-not (Test-Path -LiteralPath $zip)) { throw "Missing archive: $zip. Download the offline release or run scripts/fetch-deps.ps1 first." }
 if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Sha256) { throw "Archive checksum mismatch: $Archive" }
 $stage = Join-Path $project ('runtime\_setup-' + [guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $stage | Out-Null
 try {
  Expand-Archive -LiteralPath $zip -DestinationPath $stage
  $sourceTree = Join-Path $stage $Top
  if (-not (Test-Path -LiteralPath $sourceTree -PathType Container)) { throw "Unexpected archive layout: $Archive" }
  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  # Overlay bundled program files only. Never delete installed worlds or configuration.
  Get-ChildItem -LiteralPath $sourceTree -Force | Copy-Item -Destination $Destination -Recurse -Force
 } finally {
  $resolved = [IO.Path]::GetFullPath($stage)
  $allowed = [IO.Path]::GetFullPath((Join-Path $project 'runtime')) + [IO.Path]::DirectorySeparatorChar
  if (-not $resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe staging cleanup path.' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
 }
}

$restored = $false
if (-not (Test-Path -LiteralPath (Join-Path $engine 'bin\luanti.exe'))) {
 Restore-BundledTree 'luanti-5.17.0-win64.zip' '3ce20c77f5c206a988d7a6b883439e2759e3cf67428c9dbcf99ecd2936da631c' 'luanti-5.17.0-win64' $engine
 $restored = $true
}
if (-not (Test-Path -LiteralPath (Join-Path $engine 'games\mineclonia\game.conf'))) {
 Restore-BundledTree 'mineclonia-0.123.1.zip' 'abeacf4e202d6e01a63119a36b46751eb6abfd42948a0b06e1ba8f63fb849e59' 'mineclonia' (Join-Path $engine 'games\mineclonia')
 $restored = $true
}
# Apply the readable, version-controlled local source files to their engine paths.
$mapping = Get-Content -LiteralPath (Join-Path $project 'overrides.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($entry in $mapping) {
 $source = [IO.Path]::GetFullPath((Join-Path $project $entry.source))
 $target = [IO.Path]::GetFullPath((Join-Path $engine $entry.target))
 if (-not $source.StartsWith($project + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe source path.' }
 if (-not $target.StartsWith($engine + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe override path.' }
 New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
 Copy-Item -LiteralPath $source -Destination $target -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $engine 'worlds') | Out-Null
$lines += "[$(Get-Date -Format s)] Complete. Restored archives: $restored"
[IO.File]::WriteAllLines((Join-Path $project 'evidence\bootstrap.log'), $lines, $utf8)
