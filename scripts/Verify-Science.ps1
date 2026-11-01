param([switch]$Offline, [switch]$PublishReport)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
try {
    if (-not $Offline) {
        dotnet restore Yorungez.slnx --locked-mode
        if ($LASTEXITCODE -ne 0) { throw 'Locked restore failed.' }
        Push-Location tools/science-js
        try {
            npm ci --ignore-scripts --no-fund --no-audit
            if ($LASTEXITCODE -ne 0) { throw 'Locked npm restore failed.' }
        }
        finally { Pop-Location }
    }
    python scripts/science/verify_snapshots.py
    if ($LASTEXITCODE -ne 0) { throw 'Saved reference integrity verification failed.' }
    dotnet test tests/Yorungez.Astronomy.Tests --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw 'Scientific reference tests failed.' }
    dotnet run --project tools/Yorungez.ScienceProbe --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw 'C# probe failed.' }
    node tools/science-js/probe.mjs
    if ($LASTEXITCODE -ne 0) { throw 'C#/JavaScript parity failed.' }
    if ($PublishReport) { python scripts/science/publish_report.py --publish }
    else { python scripts/science/publish_report.py }
    if ($LASTEXITCODE -ne 0) { throw 'Report verification failed.' }
}
finally { Pop-Location }
