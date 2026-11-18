$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$compilerPath = Join-Path $projectRoot '.tools/luau/luau-compile.exe'
$runtimePath = Join-Path $projectRoot '.tools/luau/luau.exe'
if (-not (Test-Path -LiteralPath $compilerPath)) { throw 'Execute primeiro scripts/Install-Tools.ps1.' }
Push-Location $projectRoot
try {
    $sourceFiles = Get-ChildItem -LiteralPath 'src' -Recurse -Filter '*.luau'
    foreach ($sourceFile in $sourceFiles) {
        & $compilerPath --null $sourceFile.FullName
        if ($LASTEXITCODE -ne 0) { throw "Luau inválido: $($sourceFile.FullName)" }
    }
    & $runtimePath tests/CaptureMath.spec.luau
    if ($LASTEXITCODE -ne 0) { throw 'Teste de captura falhou.' }
    foreach ($runnerPath in @('tests/run_capture_tests.py', 'tests/run_data_tests.py')) {
        if (Test-Path -LiteralPath $runnerPath) {
            python $runnerPath --luau $runtimePath
            if ($LASTEXITCODE -ne 0) { throw "Teste falhou: $runnerPath" }
        }
    }
    & (Join-Path $PSScriptRoot 'Build.ps1')
} finally { Pop-Location }

