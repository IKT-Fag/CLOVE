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

        Set-VM `
            -VM $_ `
            -MemoryGB $RamGB `
            -Confirm:$False

        ## We have to access the API, because PowerCli doesn't
        ## support setting the number of cores - only sockets..?
        ## https://communities.vmware.com/thread/342422
        $spec = New-Object -Type VMware.Vim.VirtualMachineConfigSpec -Property @{"NumCoresPerSocket" = $NumCores;"numCPUs" = $NumSockets}
        $_.ExtensionData.ReconfigVM_Task($spec)

    }

    Disconnect-VIServer * -Confirm:$False | Out-Null
}

$Cred = Get-Credential
$Hosts = @(
    "172.16.0.165"
    "172.16.0.164"
    "172.16.0.163"
    "172.16.0.162"
    "172.16.0.161"
    "172.16.0.166"
)

Set-ESXiHostSpecs -Server 192.168.0.9 -Credential $cred -RamGB 32 -NumSockets 8 -NumCores 8
