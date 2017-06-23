Import-Module vmware.vimautomation.core, posh-ssh

Disconnect-VIServer * -Confirm:$False -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

$Domain = "IKT-FAG"
$Cred = Get-Credential
$CredDomain = Get-Credential

function Send-Ping($IP)
{
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Ping.send($IP)
}

<#
$Hosts = @{
    "172.16.0.180" = @(
        "16benvea",
        "16garkyl",
        "16dantra",
        "16lucfje"
    )
    "172.16.0.181" = @(
        "16alesyr",
        "16olemol",
        "16marvan",
        "16tombra"
    )
    "172.16.0.182" = @(
        "16martho",
        "16stebor",
        "16heleln"
    )
    "172.16.0.183" = @(
        "16marell",
        "16marhof"
    )
    "172.16.0.184" = @(
        "16sigjak",
        "16emigaa",
        "16marfos",
        "16marhol"
    )
    "172.16.0.185" = @(
        "16odilei",
        "16danlob"
    )
}
#>

$JsonFiles = Get-Childitem -Path "C:\Users\admin\Documents\GitHub\CLOVE\Json\Individuelle"
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

    ## Start by leaving domain
    ## I do this because domain integration regularly breaks in spectacular ways.
    ## Trust me.
    $VMHost = Get-VMHost -Server $IP
    $Auth = $VMHost | Get-VMHostAuthentication
    $Auth | Set-VMHostAuthentication -VMHostAuthentication -LeaveDomain -Confirm:$False -Force
    $Auth | Set-VMHostAuthentication -LeaveDomain -Confirm:$False -Force
    ## Now we need to SSH into the host to restart all of the services.
    ## Don't ask me why.
    #$Command = "/usr/sbin/services.sh restart"
    #$Session = New-SSHSession -ComputerName $IP -AcceptKey -KeepAliveInterval 1 -Credential $cred
    #$Output = Invoke-SSHCommand -Command $Command -SSHSession $Session -EnsureConnection -TimeOut 120
    #Write-Output $Output

    $VMHost = Get-VMHost -Server $IP
    $Auth = $VMHost | Get-VMHostAuthentication
    $Auth | Set-VMHostAuthentication -Domain $Domain -Credential $CredDomain -JoinDomain

    ## Remove old permissions
    $Permissions = Get-VIPermission -Server $IP
    foreach ($User in $Permissions)
    {
        if ($User.Principal -like "*petter") { write "SKIP PETTER"; continue }
        if ($User.Principal -like "*admins*") { write "SKIP ADMIN GROUP"; continue }
        if ($User.Principal -like "IKT-FAG\*")
        {
            $User.Principal
            Remove-VIPermission -Permission $User -Confirm:$False
        }
    }

    $RetryCount = 0
    while (!($VIAccount) -and ($RetryCount -le 15))
    {
        Write-Output "Current retry count: $RetryCount"
        $VIAccount = Get-VIAccount -Server $IP -Domain $Domain -User $User
        New-VIPermission -Principal $VIAccount -Entity $IP -Role "Admin" -Propagate -ErrorAction Continue
        $RetryCount++
        Start-Sleep -Seconds 2
    }

    <## Add new vipermissions
    foreach ($User in $ESXi.Value)
    {
        $RetryCount = 0
        while (!($VIAccount) -and ($RetryCount -le 10))
        {
            Write-Output "Current retry count: $RetryCount"
            $VIAccount = Get-VIAccount -Server $IP -Domain $Domain -User $User
            New-VIPermission -Principal $VIAccount -Entity $IP -Role "Admin" -Propagate -ErrorAction Continue
            $RetryCount++
            Start-Sleep -Seconds 5
        }
    }#>

    Disconnect-VIServer -Server $IP -Confirm:$False
}
