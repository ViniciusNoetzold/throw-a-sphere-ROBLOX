$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$rojoPath = Join-Path $projectRoot '.tools/rojo/rojo.exe'
if (-not (Test-Path -LiteralPath $rojoPath)) { $rojoPath = (Get-Command rojo -ErrorAction Stop).Source }
Push-Location $projectRoot
try {
    & $rojoPath serve default.project.json --address 127.0.0.1 --port 34872
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao iniciar servidor Rojo.' }
} finally { Pop-Location }

