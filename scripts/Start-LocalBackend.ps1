param([string]$Url = 'http://127.0.0.1:5187', [string]$FrontendUrl = 'http://127.0.0.1:5190', [ValidateSet('Auto','Gmail','Mailpit')][string]$EmailMode = 'Auto')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
$previousEnvironment = $env:ASPNETCORE_ENVIRONMENT
$previousFrontend = $env:Email__FrontendBaseUrl
. (Join-Path $PSScriptRoot 'LocalEmailEnvironment.ps1')
try {
    & (Join-Path $PSScriptRoot 'Initialize-LocalEnvironment.ps1')
    docker compose up -d --wait
    if ($LASTEXITCODE -ne 0) { throw 'Local containers could not start. Check .env ports; existing services are not stopped.' }
    dotnet restore Yorungez.slnx --locked-mode
    if ($LASTEXITCODE -ne 0) { throw 'Package restore failed.' }
    dotnet build Yorungez.slnx --configuration Release --no-restore
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:Email__FrontendBaseUrl = $FrontendUrl
    Invoke-WithLocalEmail -Mode $EmailMode -Action {
        dotnet run --project src/Yorungez.Api --configuration Release --no-build -- --migrate
        if ($LASTEXITCODE -ne 0) { throw 'Local migration failed.' }
        Write-Output 'API is starting. Stop it with Ctrl+C; docker compose stop stops only this project''s containers.'
        dotnet run --project src/Yorungez.Api --configuration Release --no-build -- --urls $Url
        if ($LASTEXITCODE -ne 0) { throw 'API exited with an error.' }
    }
}
finally { $env:ASPNETCORE_ENVIRONMENT = $previousEnvironment; $env:Email__FrontendBaseUrl = $previousFrontend; Pop-Location }
