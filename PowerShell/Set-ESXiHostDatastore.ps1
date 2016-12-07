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
        Connect-VIServer -Server $VIServer -Credential $Credential -Force -WarningAction SilentlyContinue 
        $VMHost = Get-VMHost -Name $VIServer

        ## Add local disk as a datastore
        ## Select the HDD with the specified disk size ($SelectDiskSize)
        $LocalDisk = (Get-ScsiLun | Where-Object { $_.CapacityGB -eq $SelectDiskSize }).CanonicalName
        New-Datastore -VMHost $VIServer -Name $LocalDSName -Path $LocalDisk -Vmfs 
        
        ## Add iscsi datastore
        Get-VMHostStorage -VMHost $VIServer | Set-VMHostStorage -SoftwareIScsiEnabled $True -Confirm:$False 
        Start-Sleep -Seconds 2

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

        Get-VMHostStorage -RescanAllHba 
        Get-VMHostStorage -RescanVmfs 

        Get-VirtualPortGroup -Name "VM Network" | `
            Get-SecurityPolicy | `
                Set-SecurityPolicy -MacChanges $True -AllowPromiscuous $True -ForgedTransmits $True

        Disconnect-VIServer * -Confirm:$False -Force
        Start-Sleep -Seconds 2
    }
}

$Cred = Get-Credential

Set-ESXiHostDatastore `
        -VIServer "172.16.0.165" `
        -SelectDiskSize 300 `
        -LocalDSName "VM STORAGE" `
        -iScsiIp "192.168.0.15" `
        -Port 3260 `
        -TargetName "iqn.2008-08.com.starwindsoftware:vsan.ikt-fag.no-iso" `
        -Credential $Cred

<#
$Hosts = @(
    "172.16.0.165"
    "172.16.0.164"
    "172.16.0.163"
    "172.16.0.162"
    "172.16.0.161"
    "172.16.0.166"
)

$Hosts | % {

    Set-ESXiHostDatastore `
        -VIServer $_ `
        -SelectDiskSize 300 `
        -LocalDSName "VM STORAGE" `
        -iScsiIp "192.168.0.15" `
        -Port 3260 `
        -TargetName "iqn.2008-08.com.starwindsoftware:vsan.ikt-fag.no-iso" `
        -Credential $Cred
        #>
#}
#>