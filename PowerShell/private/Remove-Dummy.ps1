## Used for removing dummy-VM's from virtual ESXi hosts.
## We are using in together with "esxi-perf-test" (@IKT-Fag Github) to test DS IOPS.

$vHostFiles = Get-ChildItem -Path "C:\Users\admin\Documents\GitHub\CLOVE\Json\GROUPS"
$JsonObjects = Get-Content $vHostFiles.FullName -raw

if (!($Credential))
{
    $Credential = Get-Credential -UserName "root" -Message "root pw vmware"
}
if (!($adm))
{
    $adm = Get-Credential -UserName "ikt-fag\Petter" -Message "ikt-fag"
}

foreach ($vHost in $JsonObjects)
{
    Invoke-Command -AsJob -JobName $vHost.VIServer -ComputerName "Sparks.ikt-fag.no" -Credential $adm -ArgumentList $vHost, $Credential -ScriptBlock {

        $vHost = $args[0]
        $Credential = $args[1]

        Import-Module VMware.VimAutomation.Core

        $SourceOVA = "C:\Users\Petter\Desktop\iops\testDeploy.ova"

        $Json = $USING:vHost

        function Send-Ping($IP)
        {
            $Ping = New-Object System.Net.NetworkInformation.Ping
            $Ping.send($IP)
        }

        $Json = $Json | ConvertFrom-Json

        $IP = $Json.VIServer
        Write-Output "Current server: $IP"

        $Response = Send-Ping -IP $IP
        if ($Response.Status -eq "Failed" -or $Response.Status -eq "TimedOut")
        {
            Write-Output "Skipping server because of ping failure: $IP"
            return
        }

        try
        {
            Connect-VIServer -Server $IP -Credential $Credential -WarningAction SilentlyContinue -ErrorAction Stop
        }
        catch 
        {
            Write-Output "Could not connect to $IP"
            Write-Output $Error[0]
            return
        }

        $VM = Get-VM
        $VM | % { $_ | Remove-VM -DeletePermanently -Confirm:$False }

        Disconnect-VIServer -Server $IP -Force -Confirm:$False
    }
}
