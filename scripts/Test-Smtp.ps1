param([ValidateSet('Gmail','Mailpit')][string]$EmailMode='Gmail')
$ErrorActionPreference='Stop'
$smtpRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'LocalEmailEnvironment.ps1')
$previousSmtpEnvironment=$env:ASPNETCORE_ENVIRONMENT
Push-Location -LiteralPath $smtpRoot
try {
    $env:ASPNETCORE_ENVIRONMENT='Development'
    Invoke-WithLocalEmail -Mode $EmailMode -Action {
        dotnet run --project src/Yorungez.Api --configuration Release --no-build -- --check-smtp
        if ($LASTEXITCODE -ne 0) { throw 'SMTP diagnostic failed. No email was sent; credentials were not printed.' }
    }
} finally { $env:ASPNETCORE_ENVIRONMENT=$previousSmtpEnvironment; Pop-Location }
