Import-Module VMware.VimAutomation.Core

$Hosts = @()
0..40 | % {
    $ip = 10 + $_
    $Hosts += "172.20.0.$ip"
}


#$Hosts = "172.20.0.10"

$VMName = "Windows Server 2016"
$cred = Get-Credential
$SourceOVA = "C:\Users\admin\Documents\CLOVE\Clean Server.ova"



$Hosts | foreach {

    Connect-VIServer $_ -Credential $cred
    
    $Datastore = Get-Datastore -Server $Hosts -Name "VM STORAGE"
    Import-VApp -Source $SourceOVA -Name $VMName -VMHost $Hosts -Datastore $Datastore -DiskStorageFormat Thin
    
    $VM = Get-VM -Name $VMName
    $VM | Get-NetworkAdapter | Remove-NetworkAdapter -Confirm:$False
    $Netadapter = Get-VirtualPortGroup | where name -Like *10.0.*
    $VM | Get-NetworkAdapter | where name -Like *10*

    $VM | New-NetworkAdapter -StartConnected -NetworkName $Netadapter -Type vmxnet3 -Confirm:$False |
        Set-NetworkAdapter -Confirm:$False

    $VM | Set-VM -NumCpu 4 -CoresPerSocket 4 -Confirm:$false

}

