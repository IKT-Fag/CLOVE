## Used for restarting services on virtual ESXi hosts.
## I've found that if they are disconnected for a long time,
## AD-integration will break. Restarting services usually fixes
## this. Also, restarting the services seems to work in general if 
## there are unexplainable issues.
Import-Module vmware.vimautomation.core, posh-ssh

Disconnect-VIServer * -Confirm:$False -Force -ErrorAction SilentlyContinue `
    -WarningAction SilentlyContinue

$Domain = "IKT-FAG"
$Cred = Get-Credential
$JsonFiles = Get-Childitem -Path "C:\Users\admin\Documents\GitHub\CLOVE\Json"

function Send-Ping($IP)
{
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Ping.send($IP)
}

foreach ($vHost in $JsonFiles)
{
    $Json = Get-Content -Path $vHost.FullName -raw | ConvertFrom-Json
    $IP = $Json.VIServer
    $UserName = $Json.User

    $Response = Send-Ping -IP $IP
    if ($Response.Status -eq "Failed" -or $Response.Status -eq "TimedOut")
    {
        Write-Output "Skipping server because of ping failure: $IP"
        continue
    }

    Write-Output $IP
    Connect-VIServer -Server $IP -Credential $cred

    ## Now we need to SSH into the host to restart all of the services.
    $Command = "/usr/sbin/services.sh restart"
    $Session = New-SSHSession -ComputerName $IP -AcceptKey -KeepAliveInterval 1 -Credential $cred
    $Output = Invoke-SSHCommand -Command $Command -SSHSession $Session -EnsureConnection -TimeOut 120
    Write-Output $Output

    Disconnect-VIServer -Server $IP -Confirm:$False
}
