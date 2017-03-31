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
        ## Used for measuring time used
        $StartTime = Get-Date

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
        #$Users = Get-ADGroupMember -Identity $obj.UserGroup -Recursive

        ## Used for deploying vESXi hosts without ad users.
        $Users = 1..30 | % {
            [PSCustomObject]@{
                Group = $_
                SamAccountName = "Dummy-$_"
            }
        }

        ## Loop through each user.
        ## $i ++ at the end
        $i = $Obj.HostIPStartFrom
        $num = 1
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
            $AllEsxi | ForEach-Object {
                if ($_.Name -eq $VMName) 
                {
                    $Skip = $True
                }
            }
            if ($Skip)
            {
                Write-Host "Detected already existing esxi host, skip."
                continue
            }

            ## Unique ovf configuration on a per-user basis
            $OvfConfig.common.guestinfo.hostname.value = $Username
            $OvfConfig.common.guestinfo.ipaddress.value = $IPAddress

            ## Start importing the ovfFile and its config
            $Params = @{
                "Source" = $Obj.OvfFile
                "OvfConfiguration" = $OvfConfig
                "Name" = $VMName
                "Location" = $Cluster
                "VMHost" = $VMHost
                "Datastore" = $Datastore
                "DiskStorageFormat" = "thin"
            }
            $VM = Import-VApp @Params

            Write-Host "Created VM, configuring.."

            ## The virtuallyGhetto appliance comes with some hdd's, but we want to
            ## create our own, so we remove them and create a new hdd.
            $VM | Get-HardDisk | Select-Object -last 2 | Remove-HardDisk -Confirm:$False | Out-Null
            $VM | New-HardDisk -DiskType "flat" -CapacityGB $Obj.HostHDDSizeGB -Datastore $Obj.vCenterDatastore -StorageFormat Thin | Out-Null
            $VM | Start-VM | Out-Null

            ## This object is returned at the end.
            $vlan = (1020 + $num)
            $subnet = "40.$(0 + $num).0.0"
            $VMObject = [PSCustomObject]@{
                User = $Username
                Vlan = $vlan
                Name = $VMName
                VIServer = $IPAddress
                Subnet = $subnet
                Netmask = $Obj.HostNetmask
                Wildcard = (Convert-NetmaskToWildcard -Netmask $Obj.HostNetmask).Wildcard
                HostSizeGB = $Obj.HostHDDSizeGB
            }
            $ObjCollection += $VMObject

            $i++
            $num++
        }

        ## We create a JSON file for each object, for use later
        $ObjCollection | ForEach-Object {
            $PSItem | ConvertTo-Json | Out-File -FilePath "$ProjectRoot\Json\Dummies\$($PSItem.Name).json" -Encoding ascii -Force
        }
        $ObjCollection

        $EndTime = Get-Date
        $Timespan = [PSCustomObject]@{
            StartTime   = $StartTime
            EndTime     = $EndTime
            TimeUsed    = $EndTime - $StartTime
        }
        Write-Output $Timespan
    }
    
    end
    {
        Disconnect-VIServer * -Confirm:$False | Out-Null
    }

}

if(!($Cred))
{
    $Cred = Get-Credential
}

$Obj = [PSCustomObject]@{
    ## For creation of host. All are required
    vCenter = "192.168.0.9"
    vCenterCred = $Cred 
    vCenterCluster = "Elev-VM" 
    vCenterDatastore = "Smith" ## The datastore you want the vHosts to be stored on
    vCenterNetwork = "Labnett" ## I use a trunk NIC for seperating vHosts, but you can use w/e you want
    vCenterVMHost = "192.168.0.20" ## This would be two eventually
    OvfFile = "C:\Users\admin\Documents\GitHub\CLOVE\ignore\Nested_ESXi6.x_Appliance_Template_v5.ova"
    HostIP = "192.168.10.xxx" ## xxx gets replaced with HostIPStartFrom (180 + 1 after the first one)
    HostIPStartFrom = 200
    HostNetmask = "255.255.255.0"
    HostGateway = "192.168.10.254"
    HostDNS = "8.8.8.8"
    HostDNSDomain = "ikt-fag.no"
    HostNTP = "0.no.pool.ntp.org"
    HostPassword = "Passord1" ## The password you want the root user to get
    HostSSH = "True"
    HostHDDSizeGB = "100" ## HDD size
    UserGroup = "Elever" ## This is an AD group, where each member gets their own ESXi host.
}

New-ESXiHost -Obj $Obj
