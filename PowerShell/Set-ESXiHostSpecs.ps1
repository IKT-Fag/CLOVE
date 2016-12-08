function Set-ESXiHostSpecs($RamGB, $NumSockets, $NumCores, $Server, $Credential)
{
    Import-Module VMWare.VimAutomation.Core

    Connect-VIServer -Server $Server -Credential $Credential -Force | Out-Null

    Get-VM | Where-Object { $_.Name -like "GROUP*" } | foreach {

        Write-Host $_.Name

        try 
        {
            Stop-VM -VM $_ -Kill -Confirm:$False -ErrorAction Stop
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViError]
        {
            Write-Host "VM was already powered off."
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]
        {
            throw $Error[0]
        }

        while ((Get-VM -Name $_.Name).PowerState -eq "PoweredOn")
        {
            Write-Host "Waiting for VM to power off."
        }

        ## Set amount of ram
        $_ | Set-VM -MemoryGB $RamGB -Confirm:$False

        ## We have to access the API, because PowerCli doesn't
        ## support setting the number of cores - only sockets..?
        ## https://communities.vmware.com/thread/342422
        $spec = New-Object -Type VMware.Vim.VirtualMachineConfigSpec -Property @{"NumCoresPerSocket" = $NumCores;"numCPUs" = $NumSockets}
        $_.ExtensionData.ReconfigVM_Task($spec)

        ## Upgrade Virtual Machine hardware
        $_ | Set-VM -Version v11 -Confirm:$False

        ## Set the guest OS to ESXi 6.x instead of 5.x (After upgrading hardware)
        $_ | Set-VM -GuestId vmkernel6Guest

        ## Support for 64 bit guests on the virtual esxi hosts
        ## https://communities.vmware.com/thread/511353?start=0&tstart=0
        $spec = New-Object -Type VMware.Vim.VirtualMachineConfigSpec
        $spec.nestedHVEnabled = $True
        $_.ExtensionData.ReconfigVM($spec)

    }

    Disconnect-VIServer * -Confirm:$False | Out-Null
}

$Cred = Get-Credential
Set-ESXiHostSpecs -Server 192.168.0.9 -Credential $cred -RamGB 32 -NumSockets 8 -NumCores 8
