$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
try {
    & (Join-Path $PSScriptRoot 'Initialize-LocalEnvironment.ps1')
    docker compose up -d --wait
    if ($LASTEXITCODE -ne 0) { throw 'Local infrastructure did not start.' }
    dotnet restore Yorungez.slnx --locked-mode
    if ($LASTEXITCODE -ne 0) { throw 'Locked package restore failed.' }
    dotnet test Yorungez.slnx --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw 'Backend verification failed.' }
}
finally { Pop-Location }
