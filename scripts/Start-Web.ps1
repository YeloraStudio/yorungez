param([ValidateRange(1024,65535)][int]$Port = 5190, [switch]$Production, [switch]$EnableLab)
$ErrorActionPreference = 'Stop'
$webRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../src/Yorungez.Web'))
$npmCommand = if ($IsWindows) { 'npm.cmd' } else { 'npm' }
$priorLab = $env:YORUNGEZ_ENABLE_LAB
Push-Location -LiteralPath $webRoot
try {
    $env:YORUNGEZ_ENABLE_LAB = if ($EnableLab) { '1' } else { '0' }
    $lockHash = (Get-FileHash -LiteralPath 'package-lock.json' -Algorithm SHA256).Hash
    $stampPath = Join-Path $webRoot 'node_modules/.yorungez-lock'
    $stampMatches = (Test-Path -LiteralPath $stampPath) -and ((Get-Content -LiteralPath $stampPath -Raw).Trim() -eq $lockHash)
    if (-not (Test-Path -LiteralPath 'node_modules/next/package.json') -or -not $stampMatches) {
        & $npmCommand ci --ignore-scripts --no-fund --no-audit
        if ($LASTEXITCODE -ne 0) { throw 'Locked frontend restore failed.' }
        Set-Content -LiteralPath $stampPath -Value $lockHash -Encoding ascii
    }
    if ($Production) {
        & $npmCommand run build
        if ($LASTEXITCODE -ne 0) { throw 'Frontend build failed.' }
        node node_modules/next/dist/bin/next start --hostname 127.0.0.1 --port $Port
    } else {
        node scripts/stage-assets.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Catalogue integrity check failed.' }
        node node_modules/next/dist/bin/next dev --webpack --hostname 127.0.0.1 --port $Port
    }
    if ($LASTEXITCODE -ne 0) { throw 'Frontend server exited with an error. Check whether the chosen port is already in use.' }
}
finally { $env:YORUNGEZ_ENABLE_LAB = $priorLab; Pop-Location }
