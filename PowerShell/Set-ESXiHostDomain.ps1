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
                if ($Error[0].Exception.Message -like "*already joined to domain*")
                {
                    Write-Host "$VIServer already joined to domain" -ForegroundColor Green
                    $Succeed = $True
                }
                elseif ($Error[0].Exception.Message -like "*Errors in Active Directory operations.*")
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
            Domain   = $Domain
        }
    }
}

$Hosts = @(0..8 | % {
        "172.20.0.$($_ + 10)"
    })
<#
connect-viserver 192.168.0.9 -Credential $cred
$Hosts | % {
    $_
    $vm =  Get-VM -Name "*$_"
    $vm | Stop-VM -kill -confirm:$False
    $vm | Start-VM
}
Disconnect-VIServer * -Confirm:$False
#>
#Start-Sleep -Seconds 240

## NOTE:
## Don't write the username like "DOMAIN\Username".
## Just use "Username"
$Cred = Get-Credential
$Hosts | % {
    Set-ESXiHostDomain `
        -VIServer $_ `
        -VIUser root `
        -VIPassword "Passord1" `
        -Domain "IKT-Fag.no" `
        -ADUser "Adrian" `
        -Credential $Cred
}

