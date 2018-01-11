Import-Module VMware.VimAutomation.Core

$Hosts = @()
0..40 | % {
    $ip = 10 + $_
    $Hosts += "172.20.0.$ip"
}

$cred = (Get-Credential)

$Hosts | foreach {


    Connect-VIServer $_ -Credential $cred


    New-Datastore -VMHost $_ -Name 'ISO' -Path naa.6589cfc000000895dc3de79a01f03cf3 -Vmfs

    Get-VMHostStorage -RescanAllHba
    Get-VMHostStorage -RescanVmfs


}

