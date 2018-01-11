## This script is only useful if you plan on giving each virtual ESXi host
## their own VLAN. This script connects to the virtual host.
## This script is closely related to "Set-PhysicalESXiHostNetworkConfig.ps1"
function Set-ESXiHostNetworkConfig($JsonPath, $Credential)
{
    Import-Module VMware.VimAutomation.Core

    $JsonFiles = Get-ChildItem -Path $JsonPath
    $JsonFiles | ForEach-Object {
        ## Load json file and make it an object.
        ## Json contains all the data we need for this.
        $JsonFile = Get-Content -Path $PSItem.FullName -Raw
        $Json = $JsonFile | ConvertFrom-Json

        Connect-VIServer -Server $Json.VIServer -Credential $Credential -Force

        ## Remove default nic
        Get-VirtualPortGroup -Name "VM Network" -Server $Json.VIServer | Remove-VirtualPortGroup -Confirm:$False

        ## Create virtual portgroup
        ## Set the security policy to allow promiscuous etc.

        New-VirtualSwitch -Name vSwitch1 -Nic vmnic1

        Get-VirtualSwitch | 
            New-VirtualPortgroup -Name $Json.Subnet -VLanId $Json.Vlan -Confirm:$False |
            Get-SecurityPolicy |
            Set-SecurityPolicy `
            -AllowPromiscuous $True `
            -ForgedTransmits $True `
            -MacChanges $True `
            -Confirm:$False

        ## Set dns
        $nw = Get-VMHostNetwork -VMHost $Json.Viserver
        Set-VMHostNetwork -Network $nw -DnsAddress "172.18.0.2", "172.18.0.3" -Confirm:$False

        Disconnect-VIServer * -Confirm:$False
    }
}

## Temp for testing
$Json = "C:\Users\admin\Documents\GitHub\CLOVE\Json\Eksamen"
$Cred = Get-Credential
Set-ESXiHostNetworkConfig -JsonPath $Json -Credential $Cred
