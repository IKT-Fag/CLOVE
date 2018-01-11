Import-Module VMware.VimAutomation.Core


Get-VM -Name *2017* | Stop-VM -Confirm:$false


Get-VM -Name *2017* | Set-VM -NumCpu 4 -CoresPerSocket 4 -Confirm:$false