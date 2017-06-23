# Usage

*NOTE: Keep in mind that CLOVE-v2 is right around the corner, with lots of usability improvements.*

## Quickstart

*NOTE: There are more detailed descriptions of every file below.* 

Unfortunately, there really is no quickstart in CLOVE-v1. It's clumsy and hard to use, and therefore I am working on a rewrite.

Anyways, to get started: (*in order*)
* New-ESXiHost.ps1
* Set-ESXiHostSpecs.ps1
* Set-PhysicalESXiHostNetworkConfig.ps1
* Set-ESXiHostNetworkConfig.ps1
* Set-ESXiHostDatastore.ps1
* Restart-Services.ps1
* Set-ESXiHostDomain.ps1

You should now have virtual ESXi-hosts! You will probably experience problems with `Set-ESXiHostDomain.ps1`. This will be fixed with CLOVE-v2. For now, the work-around is manually doing it on the vHosts that fail.

## New-ESXiHost.ps1

The first thing you should look at, is the file `PowerShell\New-ESXiHost.ps1`. This script will always be the first step in creating new virtual ESXi hosts.

At the bottom of the script, there's an object that gets passed into the function `New-ESXiHost`. You need to edit the properties inside of this object ot suit your needs.

```PowerShell
$Obj = [PSCustomObject]@{
    ## For creation of host. All are required
    vCenter = "192.168.0.9"        ## Your vCenter IP here
    vCenterCred = $Cred            ## [PSCredential] object with vCenter credentials
    vCenterCluster = "Elev-VM"     ## The cluster where you want to place your vms
    vCenterDatastore = "Smith"     ## The datastore you want the vHosts to be stored on
    vCenterNetwork = "Labnett"     ## The vNIC that gets assigned to the vHosts
    vCenterVMHost = "192.168.0.20" ## VMHost to host your vm's
    ## Ovf File downloaded from vGhetto's site: http://bit.do/VirtualAppliance
    OvfFile = "C:\Users\admin\Documents\GitHub\CLOVE\ignore\Nested_ESXi6.0u3_Appliance_Template_v1.0.ova"
    HostIP = "192.168.10.xxx"      ## xxx gets replaced with HostIPStartFrom (180 + 1 after the first one)
    HostIPStartFrom = 200          ## See above ^
    HostNetmask = "255.255.255.0" 
    HostGateway = "192.168.10.254"
    HostVlan = 300                 ## Vlan for host management interface. Set to $Null for default
    HostDNS = "8.8.8.8"
    HostDNSDomain = "ikt-fag.no"
    HostNTP = "0.no.pool.ntp.org"
    HostPassword = "Passord1"      ## The password you want the root user to get
    HostSSH = "True"               ## Enable SSH on hosts?
    HostHDDSizeGB = "100"          ## HDD size
    UserGroup = "Elever"           ## This is an AD group, where each member gets their own ESXi host.
}
```

## Set-ESXiHostSpecs.ps1

This script configures virtual machine specifications like cpu, ram etc. It should be quite straight-forward to use.

```PowerShell
$Cred = Get-Credential
Set-ESXiHostSpecs -Server 192.168.0.9 -Credential $cred -RamGB 4 -NumSockets 1 -NumCores 4
```

## Set-PhysicalESXiHostNetworkConfig.ps1

This file sets the "physical" network configuration. It creates a new virtual port group that is dedicated to CLOVE vm's, with the required config. It also adds a vNIC to the vm's that you specify, via the exported JSON-files from `New-ESXiHost.ps1`

To use it, simply go to the bottom of the file. There you'll see the parameters that you will need to change.

```PowerShell
## The VMHost
@("192.168.0.20") | % {
    Set-PhysicalESXiHostNetworkConfig `
        ## VMHost
        -VIServer $PSItem `
        ## Path to exported JSON-files
        -JsonPath "C:\Users\pette\Documents\GitHub\Create-Virtual-ESXi-Hosts\Json\GROUPS" `
        ## What you want to call the new vNic
        -vNicName "TrunkNic" `
        ## Do you want to remove all other vNIC's from the vm's?
        -RemoveAllOtherNics $True `
        ## VMHost credentials
        -Credential (Get-Credential)
}
```

## Set-ESXiHostNetworkConfig.ps1

This script is mostly useful if you need to have a NIC with a seperate vlan for each host. It loads configuration exported to JSON, and then creates a new vNIC with the specified vlanid.

```PowerShell
## JSON path
$Json = "C:\Users\admin\Documents\GitHub\CLOVE\Json"
## vHost credential. Username:root, Password:Whatever you set in New-ESXiHost
$Cred = Get-Credential

Set-ESXiHostNetworkConfig -JsonPath $Json -Credential $Cred
```

## Set-ESXiHostDatastore.ps1

This script will configure each virtual ESXi-host with specified datastores. It also creates a datastore from the local disk with the specified size.

Example:

```PowerShell
$Cred = Get-Credential

$Hosts = @()
0..9 | % {
    $ip = 150 + $_
    $Hosts += "172.16.0.$ip"
}

$Hosts | % {
    Set-ESXiHostDatastore `
        -VIServer $_ `
        -SelectDiskSize 250 `
        -LocalDSName "VM Storage" `
        -iScsiIp "192.168.0.15" `
        -Port 3260 `
        -TargetName "iqn.2008-08.com.starwindsoftware:vsan.ikt-fag.no-iso" `
        -Credential $Cred
}
```

## Restart-Services.ps1

This script's only purpose is to restart every service on the specified ESXi-host(s). I do this because domain join via PowerCLI seems to be extremely unstable, and I've found that if I restart all services first, domain join works more often.

You need to change these lines:

```PowerShell
$Domain = "IKT-FAG"
$Cred = Get-Credential
$JsonFiles = Get-Childitem -Path "C:\Users\admin\Documents\GitHub\CLOVE\Json\Eksamen"
```

## Set-ESXiHostDomain.ps1

Joins the virtual ESXi-hosts to a domain.

*Keep in mind that in CLOVE-v1, this is very unstable. Won't fix until CLOVE-v2.*

```PowerShell
$Hosts = @(0..8 | % {
    "172.16.0.$($_ + 150)"
})

## NOTE:
## Don't write the username like "DOMAIN\Username".
## Just use "Username"
$Cred = Get-Credential
$Hosts | % {
    Set-ESXiHostDomain `
        -VIServer $_ `
        -VIUser "root" `
        -VIPassword "ChangeMe" `
        -Domain "IKT-Fag.no" `
        -ADUser "Petter" `
        -Credential $Cred
}
```
