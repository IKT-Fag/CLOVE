function New-ESXiHost
{
    param
    (
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            Position = 0
        )]
        $Obj
    )

    begin
    {
        $ProjectRoot = Split-Path -Path $PSScriptRoot

        ## Both modules required
        Import-Module VMware.VimAutomation.Core, ActiveDirectory

        ## Custom imports
        . $PSScriptRoot\private\Convert-NetmaskToWildcard.ps1
    }

    process
    {
        ## Collecting objects later on
        $ObjCollection = @()

        Write-Host "Connecting to viserver.."

        $vCenter = Connect-VIServer -Server $Obj.vCenter -Credential $Obj.vCenterCred
        
        ## Datastore refrence
        $Datastore = Get-Datastore -Name $Obj.vCenterDatastore
        ## VM network refrence
        $VMNetwork = Get-VirtualPortGroup -Name $Obj.vCenterNetwork -VMHost $Obj.vCenterVMHost
        ## Cluster refrence
        $Cluster = Get-Cluster -Name $Obj.vCenterCluster
        ## Getting the vmhost from the cluster
        $VMHost = $Cluster | Get-VMHost -Name $obj.vCenterVMHost

        ## Ovf config common to all virtual ESXi hosts
        $OvfConfig = Get-OVfConfiguration -Ovf $Obj.OvfFile
        $OvfConfig.NetworkMapping.VM_Network.value = $VMNetwork
        $OvfConfig.common.guestinfo.netmask.value = $Obj.HostNetmask
        $OvfConfig.common.guestinfo.gateway.value = $Obj.HostGateway
        $OvfConfig.common.guestinfo.dns.value = $Obj.HostDNS
        $OvfConfig.common.guestinfo.domain.value = $Obj.HostDNSDomain
        $OvfConfig.common.guestinfo.ntp.value = $Obj.HostNTP
        $OvfConfig.common.guestinfo.password.value = $Obj.HostPassword
        $OvfConfig.common.guestinfo.ssh.value = $Obj.HostSSH

        ## Get users based on the UserGroup AD-group
        $Users = Get-ADGroupMember -Identity $obj.UserGroup -Recursive
         
        Write-Host "Loaded users"

        ## Loop through each user.
        ## $i ++ at the end
        $i = $Obj.HostIPStartFrom
        foreach ($User in $Users)
        {
            ## VM name is created from username and ip,
            ## but you can make this whatever you want.
            $Username = $User.SamAccountName
            $IPAddress = ($Obj.HostIP) -replace "xxx", $i
            $VMName = "$Username - $IPAddress"

            Write-Host "Current user: $Username"

            ## Checking if the VM already exists (by $VM.Name)
            $Skip = $False
            $AllEsxi = Get-VM
            $AllEsxi | foreach {
                if ($_.Name -like "*$Username*") 
                {
                    $Skip = $True
                }
            }
            if ($Skip -eq $True)
            {
                Write-Host "Detected already existing esxi host, skip."
                continue
            }

            ## Unique ovf configuration on a per-user basis
            $OvfConfig.common.guestinfo.hostname.value = $Username
            $OvfConfig.common.guestinfo.ipaddress.value = $IPAddress

            ## Start importing the ovfFile and its config
            $VM = Import-VApp `
                -Source $Obj.OvfFile `
                -OvfConfiguration $OvfConfig `
                -Name $VMName `
                -Location $Cluster `
                -VMHost $VMHost `
                -Datastore $Datastore `
                -DiskStorageFormat thin

            Write-Host "Created VM, configuring.."

            ## The virtuallyGhetto appliance comes with some hdd's, but we want to
            ## create our own, so we remove them and create a new hdd.
            $VM | Get-HardDisk | Select-Object -last 2 | Remove-HardDisk -Confirm:$False | Out-Null
            $VM | New-HardDisk -DiskType "flat" -CapacityGB $Obj.HostHDDSizeGB -Datastore $Obj.vCenterDatastore -StorageFormat Thin | Out-Null
            $VM | Start-VM | Out-Null

            ## This object is returned at the end.
            $VMObject = [PSCustomObject]@{
                User = $Username
                Vlan = (1010 + $i)
                Name = $VMName
                VIServer = $IPAddress
                Subnet = "127.16.0.0"
                Netmask = $Obj.HostNetmask
                Wildcard = (Convert-NetmaskToWildcard -Netmask $Obj.HostNetmask).Wildcard
                HostSizeGB = $Obj.HostHDDSizeGB
            }
            $ObjCollection += $VMObject

            $i++
        }

        ## We create a JSON file for each object, for use later
        $ObjCollection | foreach {
            $PSItem | ConvertTo-Json | Out-File -FilePath "$ProjectRoot\Json\$($PSItem.Name).json" -Encoding ascii -Force
        }
        $ObjCollection
    }
    
    end
    {
        Disconnect-VIServer * -Confirm:$False | Out-Null
    }

}

$Cred = Get-Credential

$Obj = [PSCustomObject]@{
    ## For creation of host. All are required
    vCenter = "192.168.0.9"
    vCenterCred = $Cred 
    vCenterCluster = "Elev-VM" 
    vCenterDatastore = "Ghost" ## The datastore you want the vHosts to be stored on
    vCenterNetwork = "TrunkNic" ## I use a trunk NIC for seperating vHosts, but you can use w/e you want
    vCenterVMHost = "192.168.0.20" ## This would be two eventually
    OvfFile = "C:\Users\admin\Documents\GitHub\Create-Virtual-ESXi-Hosts\ignore\Nested_ESXi6.x_Appliance_Template_v5.ova"
    ## www.virtuallyghetto.com/2015/12/deploying-nested-esxi-is-even-easier-now-with-the-esxi-virtual-appliance.html
    HostIP = "172.16.0.xxx" ## xxx gets replaced with HostIPStartFrom (180 + 1 after the first one)
    HostIPStartFrom = 180
    HostNetmask = "255.255.255.0"
    HostGateway = "172.16.0.1"
    HostDNS = "172.18.0.2"
    HostDNSDomain = "ikt-fag.no"
    HostNTP = "0.no.pool.ntp.org"
    HostPassword = "******************" ## The password you want the root user to get
    HostSSH = "False"
    HostHDDSizeGB = "300" ## HDD size
    UserGroup = "Elever" ## This is an AD group, where each member gets their own ESXi host.
}
