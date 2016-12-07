## This script is only useful if you plan on giving each virtual ESXi host
## their own VLAN. This script connects to the virtual host.
## This script is closely related to "Set-PhysicalESXiHostNetworkConfig.ps1"
function Set-ESXiHostNetworkConfig($JsonPath, $Credential)
{
    Import-Module VMware.VimAutomation.Core

    $JsonFiles = Get-ChildItem -Path $JsonPath
    $JsonFiles | foreach {
        ## Load json file and make it an object.
        ## Json contains all the data we need for this.
        $JsonFile = Get-Content -Path $PSItem.FullName -Raw
        $Json = $JsonFile | ConvertFrom-Json

        Connect-VIServer -Server $Json.VIServer -Credential $Credential -Force | Out-Null

        ## Create virtual portgroup
        ## Set the security policy to allow promiscuous etc.
        Get-VirtualSwitch | 
            New-VirtualPortgroup -Name $Json.Subnet -VLanId $Json.Vlan -Confirm:$False |
                Get-SecurityPolicy |
                    Set-SecurityPolicy `
                    -AllowPromiscuous $True `
                    -ForgedTransmits $True `
                    -MacChanges $True `
                    -Confirm:$False

        Disconnect-VIServer * -Confirm:$False
    }
}

## Temp for testing
$Json = "C:\Users\pette\Documents\GitHub\Create-Virtual-ESXi-Hosts\Json\GROUPS"
$Cred = Get-Credential
Set-ESXiHostNetworkConfig -JsonPath $Json -Credential $Cred
