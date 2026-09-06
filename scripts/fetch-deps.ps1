param()
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$cache = Join-Path $project 'downloads'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$lock = Get-Content -LiteralPath (Join-Path $project 'dependencies.lock.json') -Raw -Encoding UTF8 | ConvertFrom-Json
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
foreach ($item in $lock.artifacts) {
 if ($item.file -ne [IO.Path]::GetFileName($item.file)) { throw 'Invalid artifact filename.' }
 if (-not $item.url.StartsWith('https://')) { throw 'Artifact URL must use HTTPS.' }
 $dest = Join-Path $cache $item.file
 if ((Test-Path -LiteralPath $dest) -and ((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant() -eq $item.sha256)) {
  Write-Output ('Verified cached ' + $item.file)
  continue
 }
 $partial = $dest + '.partial'
 Write-Output ('Downloading ' + $item.file)
 Invoke-WebRequest -Uri $item.url -OutFile $partial -UseBasicParsing
 if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.sha256) { throw ('Checksum mismatch: ' + $item.file) }
 Move-Item -LiteralPath $partial -Destination $dest -Force
}
Write-Output 'All pinned runtime and source archives are ready for offline use.'
