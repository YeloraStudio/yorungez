[CmdletBinding(SupportsShouldProcess)]
param([ValidateRange(1024,65535)][int]$Port=5196,[string]$DeviceId,[switch]$Remove)
$ErrorActionPreference='Stop'
$action=if($Remove){'Remove this port forwarding only'}else{'Forward this one Yorungez port over an already authorized Android debugging connection'}
if(-not $PSCmdlet.ShouldProcess("Android localhost:$Port",$action)){return}
$adb=Get-Command adb -ErrorAction SilentlyContinue
if(-not $adb){throw 'Android SDK platform-tools (adb) was not found. Install it from the official Android SDK source first.'}
if(-not $Remove){
    try {
        $pack=Invoke-RestMethod -Uri "http://127.0.0.1:$Port/pwa-pack.json" -TimeoutSec 5
        if($pack.version -notmatch '^[a-f0-9]{20}$' -or '/pwa/catalog.json' -notin $pack.core.url){throw 'Not a built Yorungez PWA'}
    } catch {throw 'A production Yorungez preview is not ready on this loopback port. Start the Web/PWA preview first.'}
}
$listing=@(& $adb.Source devices 2>&1)
if($LASTEXITCODE -ne 0){throw 'Android device discovery failed. Check the USB connection and installed Android SDK.'}
$devices=@(foreach($line in $listing){if([string]$line -match '^(\S+)\s+(device|unauthorized|offline)\s*$'){[pscustomobject]@{id=$Matches[1];state=$Matches[2]}}})
if($DeviceId){$devices=@($devices|Where-Object {$_.id -ceq $DeviceId})}
if($devices.Count -ne 1){throw 'Connect one Android phone, or select one explicitly with -DeviceId. No device identifiers were printed or stored.'}
if($devices[0].state -ne 'device'){throw 'Unlock the phone and approve USB debugging for this computer on the phone. No port forwarding was created.'}
$selected=$devices[0].id
$existing=@(& $adb.Source -s $selected reverse --list 2>&1)
if($LASTEXITCODE -ne 0){throw 'Existing Android port forwarding could not be checked.'}
foreach($line in $existing){if([string]$line -match "\s+tcp:$Port\s+(\S+)" -and $Matches[1] -ne "tcp:$Port"){throw 'The phone port already forwards elsewhere. Choose another preview port; no mapping was replaced or removed.'}}
if($Remove){
    $result=@(& $adb.Source -s $selected reverse --remove "tcp:$Port" 2>&1)
    if($LASTEXITCODE -ne 0){throw 'This port forwarding could not be removed. The phone may have disconnected.'}
    Write-Output "Removed Android localhost:$Port forwarding. Other ports and phone settings were left alone."
} else {
    $result=@(& $adb.Source -s $selected reverse "tcp:$Port" "tcp:$Port" 2>&1)
    if($LASTEXITCODE -ne 0){throw 'The authorized Android connection could not forward this port.'}
    Write-Output "Open http://localhost:$Port/en (or /tr) in Chrome on the phone. Keep the USB connection and PC preview running."
    Write-Output "Remove this mapping after testing: ./scripts/Connect-AndroidPreview.ps1 -Port $Port -Remove"
}
