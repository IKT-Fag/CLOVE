Import-Module VMware.VimAutomation.Core


##This process is temp manually for now

Connect-VIServer -Server 172.20.0.10 -User root -Password Passord1

$User = "IKT-FAG\2017Usr"

$rootFolder = Get-Folder -NoRecursion
$permissions1 = New-VIPermission -Entity $rootFolder -Principal $User -Role Admin


Disconnect-VIServer -Server * -ErrorAction SilentlyContinue -Confirm:$false