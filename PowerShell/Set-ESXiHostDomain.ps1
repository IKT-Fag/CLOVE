function Set-ESXiHostDomain
{
    param
    (
        [Parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True,
            Position = 0
        )]
        $VIServer,

        [Parameter(
            Mandatory = $True
        )]
        $VIUser,

        [Parameter(
            Mandatory = $True
        )]
        $VIPassword,

        [Parameter(
            Mandatory = $True
        )]
        $Domain,

        [Parameter(
            Mandatory = $True
        )]
        $ADUser,

        [Parameter(
            Mandatory = $True
        )]
        $Credential
    )

    begin
    {
        Import-Module VMware.VimAutomation.Core
        $ErrorActionPreference = "Stop"
    }

    process
    {
        Connect-VIServer -Server $VIServer -User $VIUser -Password $VIPassword `
            -Force -WarningAction SilentlyContinue | Out-Null
        $VMHost = Get-VMHost -Name $VIServer

        Write-Host $VIServer

        ## Joining to domain
        $Succeed = $Null
        while (-not $Succeed)
        {
            try 
            {
                ## Change auth mode to domain
                Get-VMHostAuthentication -VMHost $VMHost `
                | Set-VMHostAuthentication `
                    -Domain $Domain `
                    -Credential $Credential `
                    -JoinDomain:$True `
                    -Confirm:$False

                $Succeed = $True
            }
            catch
            {
                if($Error[0].Exception.Message -like "*already joined to domain*")
                {
                    Write-Host "$VIServer already joined to domain" -ForegroundColor Green
                    $Succeed = $True
                }
                else
                {
                    Write-Warning "Domain join failed, trying again.."
                    Start-Sleep -Seconds 5
                    $Succeed = $False
                }
            }
        }

        Start-Sleep -Seconds 1

        ## Starting to configure user rights.
        ## By default, ESX Admins are added.
        ## Here we add the individual user to the host, with full admins rights.
        $RetryCount = 0
        while ((-not $VIAccount) -and ($RetryCount -ge 6))
        {
            try 
            {
                $VIAccount = Get-VIAccount -Server $VIServer -Domain "IKT-Fag" -User $ADUser -ErrorAction Stop
                New-VIPermission -Principal $VIAccount -Role "Admin" -Entity $VMHost -ErrorAction Stop
            }
            catch 
            {
                Write-Warning "Permissions failed, trying again $RetryCount"
                $VIAccount = $Null
                Start-Sleep -Seconds 5
                $RetryCount += 1
            }
        }

        Disconnect-VIServer * -Confirm:$False | Out-Null

        ## Return this
        [PSCustomObject]@{
            VIserver = $VIServer
            Domain = $Domain
        }
    }
}
Set-ESXiHostDomain `
    -VIServer "172.16.0.165" `
    -VIUser "root" `
    -VIPassword "root-password-for-vhost" `
    -Domain "IKT-Fag.no" `
    -ADUser "Petter" <# This user is added as an approved user to login to host #> `
    -Credential $Cred ## AD credentials for authenticating domain join

<#
$Cred = Get-Credential
$Hosts = @(
    "172.16.0.165"
    "172.16.0.164"
    "172.16.0.163"
    "172.16.0.162"
    "172.16.0.161"
    "172.16.0.166"
)

$Hosts | % {
    Set-ESXiHostDomain `
        -VIServer $_ `
        -VIUser root `
        -VIPassword ***`
        -Domain "IKT-Fag.no" `
        -ADUser "harald" `
        -Credential $Cred
}

#>
