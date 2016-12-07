function Set-PhysicalESXiHostNetworkConfig($VIServer, $JsonPath, $Credential, $vNicName, $RemoveAllOtherNics = $False)
{
    Import-Module VMware.VimAutomation.Core

    Connect-VIServer -Server $VIServer -Credential $Credential -Force | Out-Null

    ## Create virtual portgroup
    ## Set the security policy to allow promiscuous etc.
    Get-VirtualSwitch | New-VirtualPortgroup -Name $vNicName -VLanId 4095 -Confirm:$False |
        Get-SecurityPolicy |
            Set-SecurityPolicy `
              -AllowPromiscuous $True `
              -ForgedTransmits $True `
              -MacChanges $True `
              -Confirm:$False

    ## Here we import the json files that were created during the creation of the 
    ## virtual ESXi hosts. We need these to know which hosts to add the new vNic to.
    $JsonFiles = Get-ChildItem -Path $JsonPath
    $JsonFiles | foreach {
        ## Load json and convert to object
        $JsonFile = Get-Content -Path $PSItem.FullName -Raw
        $Json = $JsonFile | ConvertFrom-Json

        ## We need to power off the VM to add a network adapter
        $VM = Get-VM -Name $Json.Name
        $VM | Stop-VM -Kill -Confirm:$False -ErrorAction SilentlyContinue

        ## If we are to remove all other NICs
        if ($RemoveAllOtherNics -eq $True)
        {
            $VM | Get-NetworkAdapter | Remove-NetworkAdapter -Confirm:$False
        }

        ## Here we add the network adapter to each of the VM's loaded from json above.
        $VM | New-NetworkAdapter -NetworkName $vNicName |
            Set-NetworkAdapter -StartConnected $True -Confirm:$False
    }

    Disconnect-VIServer * -Confirm:$False
}

@("192.168.0.20") | % {
    Set-PhysicalESXiHostNetworkConfig `
        -VIServer $PSItem `
        -JsonPath "C:\Users\pette\Documents\GitHub\Create-Virtual-ESXi-Hosts\Json\GROUPS" `
        -vNicName "TrunkNic" `
        -RemoveAllOtherNics $True `
        -Credential (Get-Credential)
}
