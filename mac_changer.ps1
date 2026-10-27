$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script must be run with administrator privileges!" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "=== Windows 11 MAC Address Changer ===" -ForegroundColor Cyan

$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (-not $adapter) {
    $adapter = Get-NetAdapter -Physical | Select-Object -First 1
}

if (-not $adapter) {
    Write-Host "Error: No suitable physical network adapter found." -ForegroundColor Red
    Pause
    Exit
}

Write-Host "`nTarget Adapter: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Yellow
Write-Host "Current MAC Address: $($adapter.MacAddress)" -ForegroundColor Gray

function Generate-ValidMac {
    $secondNibble = ('2', '6', 'A', 'E') | Get-Random
    $firstByte = "{0:X1}{1}" -f (Get-Random -Minimum 0 -Maximum 16), $secondNibble

    $bytes = @($firstByte)
    for ($i = 0; $i -lt 5; $i++) {
        $bytes += "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 256)
    }
    return ($bytes -join "")
}

$newMac = Generate-ValidMac
Write-Host "Generated New MAC: $newMac" -ForegroundColor Green

$classPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
$targetKey = $null

Get-ChildItem -Path $classPath -ErrorAction SilentlyContinue | ForEach-Object {
    $netCfgInstanceId = (Get-ItemProperty -Path $_.PsPath -Name "NetCfgInstanceId" -ErrorAction SilentlyContinue).NetCfgInstanceId
    if ($netCfgInstanceId -eq $adapter.InterfaceGuid) {
        $targetKey = $_.PsPath
    }
}

if (-not $targetKey) {
    Write-Host "Error: Registry key not found." -ForegroundColor Red
    Pause
    Exit
}

try {
    Set-ItemProperty -Path $targetKey -Name "NetworkAddress" -Value $newMac -Force

    Write-Host "`nRestarting network adapter, please wait..." -ForegroundColor Yellow
    Disable-NetAdapter -Name $adapter.Name -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $adapter.Name -Confirm:$false
    Start-Sleep -Seconds 3

    $refreshedAdapter = Get-NetAdapter -Name $adapter.Name
    Write-Host "`nOPERATION COMPLETE!" -ForegroundColor Green
    Write-Host "Current System MAC: $($refreshedAdapter.MacAddress)" -ForegroundColor Cyan
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to close this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
