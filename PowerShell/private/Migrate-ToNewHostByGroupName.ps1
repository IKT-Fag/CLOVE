Import-Module vmware.vimautomation.core, ActiveDirectory

Connect-VIServer 192.168.0.9

$Groups = "2isa", "2isb"

$Groups | % {
        $Group = $_
        $GroupMember = (Get-ADGroupMember -Identity $Group | Select SamAccountName).SamAccountName
        $GroupMember

        Get-VM | ? { $_.Name -like "16*" } | % {

            $VMName = $_.Name
            $Username = (($_.Name).Split("-"))[0] -replace " ", ""
            $ADUser = Get-ADUser -Filter "SamAccountName -eq '$Username'"
        }

}