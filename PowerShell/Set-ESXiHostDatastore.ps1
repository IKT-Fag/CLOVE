function Set-ESXiHostDatastore
{
    param
    (
        [Parameter(
            Mandatory = $True,
            ValueFromPipelineByPropertyName = $True
        )]
        $VIServer,

        [Parameter(
            Mandatory = $True
        )]
        $SelectDiskSize,

        [Parameter(
            Mandatory = $True
        )]
        $LocalDSName = "datastore",

        [Parameter(
            Mandatory = $True
        )]
        $iScsiIp,

        [Parameter(
            Mandatory = $True
        )]
        $Port,

        [Parameter(
            Mandatory = $True
        )]
        $TargetName,

        [Parameter(
            Mandatory = $True
        )]
        $Credential
    )

    begin
    {
        Import-Module VMWare.VimAutomation.Core
        $ErrorActionPreference = "Continue"
    }

    process
    {
        $VIServer
        Connect-VIServer -Server $VIServer -Credential $Credential -Force #-WarningAction SilentlyContinue 

        Write-Host "Getting vmhost refrence.."
        ## Get a refrence to the vmhost
        $VMHost = Get-VMHost -Name $VIServer

        if ((Get-Datastore).Name -eq "VM STORAGE")
        {
            Write-Host "DS already exists, skipping host."
            #return
        }

        ## Add local disk as a datastore
        ## Select the HDD with the specified disk size ($SelectDiskSize)
        $LocalDisk = ((Get-ScsiLun -VmHost $VMHost | Where-Object { $_.CapacityGB -eq $SelectDiskSize }).CanonicalName) | Select-Object -First 1
        New-Datastore -VMHost $VIServer -Name $LocalDSName -Path $LocalDisk -Vmfs 
        
        ## Add iscsi datastore
        #Get-VMHostStorage -VMHost $VIServer | Set-VMHostStorage -SoftwareIScsiEnabled $True -Confirm:$False 
        #Start-Sleep -Seconds 2

        if ((Get-Datastore).Name -eq "ISO")
        {
            Write-Host "ISO DS exist."
            return
        }
        <#
        ## Remove storage
        Get-IScsiHbaTarget | Remove-IScsiHbaTarget -Confirm:$False

        $iScsiHBA = Get-VMHostHba -VMHost $VIServer -Type IScsi
        New-IScsiHbaTarget `
            -IScsiHba $iScsiHBA `
            -Address $iScsiIp `
            -Port $Port `
            -IScsiName $TargetName `
            -Type Static `
            -ChapType Prohibited

        #>
        Get-VMHostStorage -RescanAllHba 
        Get-VMHostStorage -RescanVmfs 

        Disconnect-VIServer * -Confirm:$False -Force
        
    }
}

$Cred = Get-Credential

$Hosts = @()
1..30 | % {
    $ip = 200 + $_
    $Hosts += "192.168.10.$ip"
}

$Hosts | % {

    Set-ESXiHostDatastore `
        -VIServer $_ `
        -SelectDiskSize 100 `
        -LocalDSName "Smith" `
        -iScsiIp "192.168.0.15" `
        -Port 3260 `
        -TargetName "iqn.2008-08.com.starwindsoftware:vsan.ikt-fag.no-iso" `
        -Credential $Cred
        #>
}
