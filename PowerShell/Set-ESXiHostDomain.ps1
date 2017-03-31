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
        [string[]]$ADUser = @(),

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
        $ProgressPreference = "SilentlyContinue"

        Connect-VIServer -Server $VIServer -User $VIUser -Password $VIPassword `
            -Force -WarningAction SilentlyContinue | Out-Null

        $VMHost = Get-VMHost -Name $VIServer
        $DomainShort = ($Domain.Split("."))[0]

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
                elseif($Error[0].Exception.Message -like "*Errors in Active Directory operations.*")
                {
                    Write "Errors in ad....."
                    Start-Sleep -Seconds 5
                    $Succeed = $False
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

        ## TODO: This is not done yet. I have to connect users to a server.
        foreach ($User in $ADUser)
        {
            $RetryCount = 0
            while ((-not $VIAccount) -and ($RetryCount -le 6))
            {
                try 
                {
                    $VIAccount = Get-VIAccount -Server $VIServer -Domain $DomainShort -User $User -ErrorAction Stop
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
        }

        Disconnect-VIServer * -Confirm:$False | Out-Null

        ## Return this
        [PSCustomObject]@{
            VIserver = $VIServer
            Domain = $Domain
        }
    }
}
<#
Set-ESXiHostDomain `
    -VIServer "172.16.0.165" `
    -VIUser "root" `
    -VIPassword "******************" `
    -Domain "IKT-Fag.no" `
    -ADUser "Petter" # This user is added as an approved user to login to host`
    -Credential $Cred ## AD credentials for authenticating domain join
#>

$Cred = Get-Credential
$Hosts = @(
    "172.16.0.180"
    "172.16.0.181"
    "172.16.0.182"
    "172.16.0.183"
    "172.16.0.184"
    "172.16.0.185"
)
connect-viserver 192.168.0.9 -Credential $cred
$Hosts | % {
    $_
    $vm =  Get-VM -Name "*$_"
    $vm | Stop-VM -kill -confirm:$False
    $vm | Start-VM

    <#
    Set-ESXiHostDomain `
        -VIServer $_ `
        -VIUser root `
        -VIPassword "******************" `
        -Domain "IKT-Fag.no" `
        -ADUser "Petter" `
        -Credential $Cred
    #>
}

