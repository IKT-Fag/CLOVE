Import-Module VMware.VimAutomation.Core

function Send-Ping($IP)
{
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Ping.send($IP)
}

$VMName = "WinSrv2016_DC001"
$cred = Get-Credential
$SourceOVA = "C:\Users\Petter\Desktop\Deploy-OVA\WIN - Ferdig-AD-Server.ova"
$JsonFiles = Get-ChildItem -Path "C:\Users\Petter\Desktop\Deploy-OVA\Individuelle"

foreach ($vHost in $JsonFiles)
{
    $Json = Get-Content -Path $vHost.FullName -raw | ConvertFrom-Json

    $IP = $Json.VIServer
    Write-Output "Current server: $IP"

    $Response = Send-Ping -IP $IP
    if ($Response.Status -eq "Failed" -or $Response.Status -eq "TimedOut")
    {
        Write-Output "Skipping server because of ping failure: $IP"
        continue
    }

    try
    {
        Connect-VIServer -Server $IP -Credential $Cred -WarningAction SilentlyContinue -ErrorAction Stop
    }
    catch 
    {
        Write-Output "Could not connect to $IP"
        Write-Output $Error[0]
        continue
    }

    if (Get-VM -Name $VMName)
    {
        Write-Output "VM already exists on this server, skipping"
        Disconnect-VIServer -Server $IP -Force -Confirm:$False
        continue
    }

    $Datastore = Get-Datastore -Server $IP -Name "VM STORAGE"
    Import-VApp -Source $SourceOVA -Name $VMName -VMHost $IP -Datastore $Datastore -DiskStorageFormat Thin

    $VM = Get-VM -Name $VMName
    $VM | Get-NetworkAdapter | Remove-NetworkAdapter -Confirm:$False
    $VM | New-NetworkAdapter -StartConnected -NetworkName "VM Network" -Type e1000e -Confirm:$False |
        Set-NetworkAdapter -Confirm:$False

    Disconnect-VIServer -Server $IP -Force -Confirm:$False
}
