param(
    [switch]$WithCreatureArt,
    [string]$CreatureDataSource,
    [string]$WorldArtSource
)
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
    if ($WithCreatureArt) {
        if ((-not $CreatureDataSource -or -not $WorldArtSource) -and (Test-Path -LiteralPath 'art/packs/art-lock.json')) {
            $bundle = 'build/bundled-art'
            python scripts/Prepare-BundledArt.py restore --destination $bundle
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao extrair o pacote de arte do repositório.' }
            if (-not $CreatureDataSource) { $CreatureDataSource = Join-Path $bundle 'data' }
            if (-not $WorldArtSource) { $WorldArtSource = Join-Path $bundle 'modelos_roblox' }
        }
        if (-not $CreatureDataSource) { $CreatureDataSource = 'art/creatures/local/data' }
        if (-not $WorldArtSource) { $WorldArtSource = '.tools/modelospokemonroblox/modelos_roblox' }
        $staging = 'build/creature-art-staging'
        New-Item -ItemType Directory -Force -Path $staging | Out-Null
        $creaturePlace = Join-Path $staging 'ThrowASphere-ComModelos.rbxlx'
        python scripts/Embed-CreatureArt.py build/ThrowASphere.rbxlx $CreatureDataSource $creaturePlace
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao incluir as criaturas.' }
        python scripts/Embed-WorldArt.py $creaturePlace $WorldArtSource build/ThrowASphere-ComModelos.rbxlx
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao incluir as orbes, as academias e a reserva.' }
        Write-Host "Arquivo com modelos: $(Join-Path $projectRoot 'build/ThrowASphere-ComModelos.rbxlx')"
    }
} finally { Pop-Location }

