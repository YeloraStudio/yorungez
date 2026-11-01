param([ValidateSet('Auto','Gmail','Mailpit')][string]$EmailMode='Auto',[ValidateRange(1024,65535)][int]$Port=5190)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$stateFile=Join-Path $projectRoot '.local/app-processes.json'
$pwsh=(Get-Command pwsh).Source
$runId=[Guid]::NewGuid().ToString('N')
foreach ($localPort in @(5187,$Port)) {
    $probe=[Net.Sockets.TcpClient]::new()
    try {
        $connect=$probe.ConnectAsync('127.0.0.1',$localPort)
        if($connect.Wait(700) -and $probe.Connected){throw "Port $localPort is in use. Existing services were left running; stop the owned app first or use the separate startup scripts."}
    } catch [AggregateException] { } finally { $probe.Dispose() }
}
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.local') -Force | Out-Null
$started=@()
function Start-AppPart([string]$name,[string]$script,[string[]]$arguments) {
    $log=Join-Path $projectRoot ".local/$name"
    $process=Start-Process -FilePath $pwsh -ArgumentList (@('-NoProfile','-File',('"'+$script+'"'))+$arguments) -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput "$log.out.log" -RedirectStandardError "$log.err.log" -PassThru
    [pscustomobject]@{name=$name;id=$process.Id;startedUtc=$process.StartTime.ToUniversalTime().ToString('O');runId=$runId}
}
$started+=Start-AppPart 'app-backend' (Join-Path $PSScriptRoot 'Start-LocalBackend.ps1') @('-EmailMode',$EmailMode,'-FrontendUrl',"http://127.0.0.1:$Port")
$started | ConvertTo-Json -AsArray | Set-Content -LiteralPath $stateFile -Encoding utf8
Write-Output 'Starting PostgreSQL, Redis and the account API. Docker Desktop must be running.'
function Wait-Endpoint([string]$url,[int]$seconds) {
    $deadline=[DateTime]::UtcNow.AddSeconds($seconds)
    do {
        foreach($record in $started){if(!(Get-Process -Id $record.id -ErrorAction SilentlyContinue)){throw 'A local app service exited before becoming ready. Check the private .local/app-*.err.log files.'}}
        try { $r=Invoke-WebRequest -Uri $url -TimeoutSec 2 -SkipHttpErrorCheck; if($r.StatusCode -eq 200){return} } catch {}
        Start-Sleep -Milliseconds 500
    } while([DateTime]::UtcNow -lt $deadline)
    throw 'App startup did not finish. Check the private .local/app-*.err.log files and Docker Desktop. Run scripts/Stop-LocalApp.ps1 before retrying.'
}
Wait-Endpoint 'http://127.0.0.1:5187/health/ready' 120
$started+=Start-AppPart 'app-web' (Join-Path $PSScriptRoot 'Start-Web.ps1') @('-Production','-Port',"$Port")
$started | ConvertTo-Json -AsArray | Set-Content -LiteralPath $stateFile -Encoding utf8
Write-Output 'Account API is ready. Building the production Web/PWA app.'
Wait-Endpoint "http://127.0.0.1:$Port/en" 120
Write-Output "Yorungez is ready: http://127.0.0.1:$Port/en (or /tr). Keep this terminal open. Ctrl+C or scripts/Stop-LocalApp.ps1 stops only these owned app processes."
try {
    while($true){
        foreach($record in $started){if(!(Get-Process -Id $record.id -ErrorAction SilentlyContinue)){throw 'A local app service exited. Check the private .local/app-*.err.log files.'}}
        Start-Sleep -Seconds 2
    }
} finally { & (Join-Path $PSScriptRoot 'Stop-LocalApp.ps1') -ExpectedRunId $runId }
