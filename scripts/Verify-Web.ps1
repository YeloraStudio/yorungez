param([switch]$Offline, [switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$webRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../src/Yorungez.Web'))
$npmCommand = if ($IsWindows) { 'npm.cmd' } else { 'npm' }
Push-Location -LiteralPath $webRoot
try {
    if (-not $Offline) {
        & $npmCommand ci --ignore-scripts --no-fund --no-audit
        if ($LASTEXITCODE -ne 0) { throw 'Locked frontend restore failed.' }
    }
    node scripts/stage-assets.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Catalogue staging failed.' }
    & $npmCommand test
    if ($LASTEXITCODE -ne 0) { throw 'Frontend science/context tests failed.' }
    & $npmCommand run typecheck
    if ($LASTEXITCODE -ne 0) { throw 'Frontend type check failed.' }
    if (-not $SkipBuild) {
        & $npmCommand run build
        if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
    }
}
finally { Pop-Location }
