$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$envPath = Join-Path $projectRoot '.env'
$localPath = Join-Path $projectRoot 'src/Yorungez.Api/appsettings.Local.json'
function Find-AvailablePort([int]$Preferred) {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Preferred)
    try { $listener.Start(); return $Preferred }
    catch [System.Net.Sockets.SocketException] {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
        try { $listener.Start(); return $listener.LocalEndpoint.Port }
        finally { $listener.Stop() }
    }
    finally { $listener.Stop() }
}
if (-not (Test-Path -LiteralPath $envPath)) {
    $postgresPassword = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
    $redisPassword = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
    $signingKey = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(64))
    @(
        "POSTGRES_PASSWORD=$postgresPassword", "REDIS_PASSWORD=$redisPassword",
        "POSTGRES_PORT=$(Find-AvailablePort 15432)", "REDIS_PORT=$(Find-AvailablePort 16379)",
        "SMTP_PORT=$(Find-AvailablePort 1029)", "MAILPIT_PORT=$(Find-AvailablePort 8029)",
        "JWT_SIGNING_KEY=$signingKey"
    ) | Set-Content -LiteralPath $envPath -Encoding utf8NoBOM
}
$values = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^([A-Z_]+)=(.*)$') { $values[$Matches[1]] = $Matches[2] }
}
foreach ($required in @('POSTGRES_PASSWORD','REDIS_PASSWORD','JWT_SIGNING_KEY')) {
    if ([string]::IsNullOrWhiteSpace($values[$required]) -or $values[$required].StartsWith('replace')) {
        throw "Configure private local value $required in .env."
    }
}
if (-not (Test-Path -LiteralPath $localPath)) {
    $settings = @{
        ConnectionStrings = @{
            Identity = "Host=127.0.0.1;Port=$($values.POSTGRES_PORT);Database=yorungez;Username=yorungez;Password=$($values.POSTGRES_PASSWORD);Include Error Detail=false"
            Redis = "127.0.0.1:$($values.REDIS_PORT),password=$($values.REDIS_PASSWORD),abortConnect=false,connectTimeout=1000,syncTimeout=1000,asyncTimeout=1000"
        }
        Jwt = @{ Issuer='https://yorungez.local'; Audience='yorungez-api'; SigningKey=$values.JWT_SIGNING_KEY }
        Email = @{ Host='127.0.0.1'; Port=[int]$values.SMTP_PORT; Sender='no-reply@yorungez.invalid'; FrontendBaseUrl='http://localhost:3000'; RequireTls=$false }
        DataProtection = @{ KeyRingPath=(Join-Path $projectRoot '.local/data-protection-keys') }
    }
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $localPath -Encoding utf8NoBOM
}
Write-Output 'Local development configuration is ready. Secrets were not printed.'
