param([switch]$NoBackup, [switch]$Check)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $project 'runtime\luanti-5.17.0-win64'
$exe = Join-Path $engine 'bin\luanti.exe'
$config = Join-Path $engine 'minetest.conf'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$hasher = [Security.Cryptography.SHA256]::Create()
try { $mutexKey = [BitConverter]::ToString($hasher.ComputeHash($utf8.GetBytes($project.ToLowerInvariant()))).Replace('-','') } finally { $hasher.Dispose() }
$mutex = New-Object System.Threading.Mutex($false, ('Local\BlockWorld_' + $mutexKey))
if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); Write-Host 'The game is already running. Please use its existing window.'; exit 1 }
try {
if (Get-Process -Name luanti -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { throw 'This game is already running. Close it before launching again.' }
& (Join-Path $PSScriptRoot 'setup.ps1')
if (-not (Test-Path -LiteralPath $exe)) { throw 'Bundled Luanti executable is missing.' }
if (-not (Test-Path -LiteralPath $config)) { Copy-Item -LiteralPath (Join-Path $project 'src\default.conf') -Destination $config }
$text = [IO.File]::ReadAllText($config)
$paths = @{
 main_menu_script = (Join-Path $project 'src\menu.lua').Replace('\','/')
 screenshot_path = (Join-Path $project 'evidence').Replace('\','/')
 fallback_font_path = (Join-Path $engine 'fonts\DroidSansFallbackFull.ttf').Replace('\','/')
 texture_path = (Join-Path $engine 'textures\local_classic_ui').Replace('\','/')
}
foreach ($key in $paths.Keys) {
 $text = [regex]::Replace($text, '(?m)^' + [regex]::Escape($key) + '\s*=.*\r?\n?', '')
 $text += "`n$key = $($paths[$key])`n"
}
[IO.File]::WriteAllText($config,$text,$utf8)
New-Item -ItemType Directory -Force -Path (Join-Path $project 'evidence'),(Join-Path $engine 'worlds') | Out-Null
if ($Check) {
 $versionProc = Start-Process -FilePath $exe -ArgumentList '--version' -NoNewWindow -Wait -PassThru
 if ($versionProc.ExitCode -ne 0) { throw 'Engine version check failed.' }
 return
}
 $proc = Start-Process -FilePath $exe -ArgumentList @('--config',('"'+$config+'"'),'--logfile',('"'+(Join-Path $project 'evidence\game.log')+'"')) -WorkingDirectory $engine -PassThru
 $proc.WaitForExit()
 if (-not $NoBackup) { & (Join-Path $PSScriptRoot 'backup.ps1') }
 if ($proc.ExitCode -ne 0) { throw ('Game exited with code ' + $proc.ExitCode + '. See evidence\game.log.') }
} finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
