# Import only the backend email keys; never print or copy secrets into generated settings.
function Invoke-WithLocalEmail {
    param([ValidateSet('Auto','Gmail','Mailpit')][string]$Mode = 'Auto', [Parameter(Mandatory)][scriptblock]$Action)
    $emailRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $emailValues = @{}
    foreach ($line in Get-Content -LiteralPath (Join-Path $emailRoot '.env')) {
        if ($line -match '^([A-Z_]+)=(.*)$') { $emailValues[$Matches[1]] = $Matches[2] }
    }
    if ($Mode -eq 'Auto') { $Mode = if ([string]::IsNullOrWhiteSpace($emailValues.EMAIL__PASSWORD)) { 'Mailpit' } else { 'Gmail' } }
    $keys = @('EMAIL__HOST','EMAIL__PORT','EMAIL__SENDER','EMAIL__USERNAME','EMAIL__PASSWORD','EMAIL__REQUIRETLS','EMAIL__RUNOUTBOXWORKER')
    $previousEmailValues = @{}
    foreach ($key in $keys) { $previousEmailValues[$key] = [Environment]::GetEnvironmentVariable($key,'Process') }
    try {
        if ($Mode -eq 'Gmail') {
            if ($emailValues.EMAIL__HOST -ne 'smtp.gmail.com' -or $emailValues.EMAIL__PORT -ne '587' -or
                $emailValues.EMAIL__REQUIRETLS -ne 'true' -or [string]::IsNullOrWhiteSpace($emailValues.EMAIL__PASSWORD) -or
                [string]::IsNullOrWhiteSpace($emailValues.EMAIL__USERNAME)) { throw 'Configure private Gmail SMTP values in .env (587/STARTTLS).' }
            foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key,[string]$emailValues[$key],'Process') }
        } else {
            $mailpit = @{ EMAIL__HOST='127.0.0.1'; EMAIL__PORT=($emailValues.SMTP_PORT ?? '1029'); EMAIL__SENDER='no-reply@yorungez.invalid'; EMAIL__USERNAME=''; EMAIL__PASSWORD=''; EMAIL__REQUIRETLS='false'; EMAIL__RUNOUTBOXWORKER='true' }
            foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key,[string]$mailpit[$key],'Process') }
        }
        & $Action
    } finally {
        foreach ($key in $keys) { [Environment]::SetEnvironmentVariable($key,$previousEmailValues[$key],'Process') }
        $emailValues.Clear(); $previousEmailValues.Clear()
    }
}
