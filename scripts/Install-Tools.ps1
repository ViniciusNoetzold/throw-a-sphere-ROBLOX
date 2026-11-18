param([switch]$InstallStudioPlugin)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolsRoot = Join-Path $projectRoot '.tools'
New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null

function Install-OfficialTool {
    param([string]$Name, [string]$Url, [string]$Sha256)
    $archivePath = Join-Path $toolsRoot "$Name.zip"
    $destinationPath = Join-Path $toolsRoot $Name
    Write-Host "Baixando $Name..."
    Invoke-WebRequest -Uri $Url -OutFile $archivePath
    $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    if ($actualHash -ne $Sha256) { throw "Checksum incorreto: $Name. Download recusado." }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $destinationPath -Force
}

Install-OfficialTool -Name 'rojo' -Url 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip' -Sha256 '2179c44862a10ecbd725bdfeb4abc64e16dc4aad9b6c8f3e1a7c46a87280b949'
Install-OfficialTool -Name 'luau' -Url 'https://github.com/luau-lang/luau/releases/download/0.747/luau-windows.zip' -Sha256 '16bbd26575e9a6a3ecd2bd5fc772a81f3232520b56a40a86f2b47fec576d7cc7'
if ($InstallStudioPlugin) {
    & (Join-Path $toolsRoot 'rojo/rojo.exe') plugin install
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível instalar o plugin Rojo no Studio.' }
}
Write-Host 'Rojo 7.7.0 e Luau 0.747 prontos em .tools/. Nenhuma mudança no PATH global.'

