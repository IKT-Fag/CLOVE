$esxHosts = @(
    "172.16.0.161"
    "172.16.0.162"
    "172.16.0.163"
    "172.16.0.164"
    "172.16.0.165"
    "172.16.0.166"
)

Import-Module Vmware.VimAutomation.Core

$Cred = Get-Credential

$esxHosts | % {
    $esx = $_

    Connect-VIServer -Server $esx -Credential $Cred

    $esx
    (Get-VIPermission).Principal

    Disconnect-VIServer -Server $esx -Confirm:$False
}