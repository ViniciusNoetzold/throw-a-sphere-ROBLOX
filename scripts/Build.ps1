$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$rojoPath = Join-Path $projectRoot '.tools/rojo/rojo.exe'
if (-not (Test-Path -LiteralPath $rojoPath)) { $rojoPath = (Get-Command rojo -ErrorAction Stop).Source }
Push-Location $projectRoot
try {
    New-Item -ItemType Directory -Force -Path 'build' | Out-Null
    & $rojoPath build default.project.json -o build/ThrowASphere.rbxlx
    if ($LASTEXITCODE -ne 0) { throw 'Falha no build Rojo.' }
    New-Item -ItemType Directory -Force -Path 'game' | Out-Null
    Copy-Item -LiteralPath 'build/ThrowASphere.rbxlx' -Destination 'game/ThrowASphere.rbxlx' -Force
    Write-Host "Arquivo pronto: $(Join-Path $projectRoot 'build/ThrowASphere.rbxlx')"
} finally { Pop-Location }

