Import-Module VMware.Vimautomation.Core

$Hosts = @()
0..40 | % {
    $ip = 10 + $_
    $Hosts += "172.20.0.$ip"
}

$communities = "ikt-fag.no"
$syslocation = "Bleiker vgs"

$cred = (Get-Credential)


$Hosts | foreach {


    Connect-VIServer $_ -Credential $cred
    $esxcli = Get-EsxCli -VMHost $_
    $esxcli.system.snmp.set($null,$communities,"true",$null,$null,$null,$null,$null,$null,$null,$null,$null,$syslocation)
    $esxcli.system.snmp.get()
    
    
    Disconnect-VIServer * -Confirm:$false


}







