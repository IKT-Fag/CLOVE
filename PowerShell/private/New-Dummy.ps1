## Used for deploying VM's to the virtual ESXi hosts.
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
        $ServerName = "Server 2016"

        ## temp to reduce load on server / DS
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 20)

        Import-Module VMware.VimAutomation.Core

        $SourceOVA = "C:\Users\Petter\Desktop\Clean Server.ova"

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

        if (Get-VM -Name $ServerName -Server $IP -ErrorAction SilentlyContinue)
        {
            Write-Output "VM already exists on this server, skipping"
            Disconnect-VIServer -Server $IP -Force -Confirm:$False
            return
        }

        $Datastore = Get-Datastore -Server $IP -Name "VM Storage"
        Import-VApp -Source $SourceOVA -Name $ServerName -Server $IP -VMHost $IP `
            -Datastore $Datastore -DiskStorageFormat Thin -ErrorAction Stop

        Disconnect-VIServer -Server $IP -Force -Confirm:$False
    }
}
