param(
    [switch]$Offline,
    [ValidateSet('Debug','Release')][string]$Configuration = 'Debug'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
try {
    if (-not $Offline) {
        dotnet restore Yorungez.slnx --locked-mode
        if ($LASTEXITCODE -ne 0) { throw 'Locked restore failed.' }
    }
    # Requires already-running project infrastructure; never starts/stops the user's application.
    dotnet test tests/Yorungez.Api.Tests --configuration $Configuration --no-restore --filter 'Category=Recovery' --verbosity minimal
    if ($LASTEXITCODE -ne 0) { throw 'Local recovery drill failed. No production database was selected.' }
}
finally { Pop-Location }
