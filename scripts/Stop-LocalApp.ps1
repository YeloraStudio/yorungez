param([switch]$StopInfrastructure,[string]$ExpectedRunId)
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$stateFile=Join-Path $projectRoot '.local/app-processes.json'
if(Test-Path -LiteralPath $stateFile){
    $owned=@(Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json)
    if($ExpectedRunId -and @($owned | Where-Object runId -ne $ExpectedRunId).Count){return}
    foreach($record in $owned){
        $process=Get-Process -Id $record.id -ErrorAction SilentlyContinue
        if(!$process -or $process.StartTime.ToUniversalTime().Ticks -ne ([DateTimeOffset]$record.startedUtc).UtcTicks){continue}
        # A matching PID and exact creation time identifies only the launcher we created.
        $processes=@(Get-CimInstance Win32_Process)
        function Stop-OwnedTree([int]$ownedProcessId){
            foreach($child in $processes | Where-Object ParentProcessId -eq $ownedProcessId){Stop-OwnedTree $child.ProcessId}
            Stop-Process -Id $ownedProcessId -ErrorAction SilentlyContinue
        }
        Stop-OwnedTree $record.id
    }
    Remove-Item -LiteralPath $stateFile
}
if($StopInfrastructure){Push-Location -LiteralPath $projectRoot;try{docker compose stop}finally{Pop-Location}}
Write-Output 'Owned local app processes stopped. Database volumes and records were retained.'
