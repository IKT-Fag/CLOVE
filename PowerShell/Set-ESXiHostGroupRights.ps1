function Set-ESXiHostGroupRights($Cred)
{
    Import-Module VMWare.VimAutomation.Core, ActiveDirectory

    $CSVPath = "D:\Google Drive\001 - IKT\00 - Bleiker Lærlingplass\IKT-Fag\Grupper tverrfaglig 2016-2.csv"
    $CSV = Import-csv -Path $CSVPath -Delimiter ";" -Encoding UTF7 -Header ("Group", "Fullname")

    $Obj = $Null
    $Obj = [PSCustomObject]@{
    }
    $EsxiHosts = @(
        #"172.16.0.165"
        "172.16.0.164"
        "172.16.0.163"
        "172.16.0.162"
        "172.16.0.161"
        "172.16.0.166"
    )
    1..$EsxiHosts.Count | % {
        $Obj | Add-Member -Name $_ -Value @() -MemberType NoteProperty
    }

    $Csv | % {
        $Group = $_.Group
        $Value = $_.Fullname

        $Obj.$Group += $Value
    }

    1..$EsxiHosts.Count | % {
        $esxi = $EsxiHosts[$_ - 1]
        $Group = $Obj.$_

        Connect-VIServer -Server $esxi -Credential $Cred

        $Users = @()
        $Group | % {
            $User = (Get-ADUser -Filter "Name -eq '$_'" | Select-Object samaccountname).samaccountname
            $Users += $User
        }

        $VMHost = Get-VMHost -Name (Get-VMHost).Name
        $RetryCount = $Null
        $Users | % {
            $User = $_
            Write-Host "In user loop"
            $RetryCount = 0

            $srv = Get-VMHostService | ? { $_.Key -eq "lwsmd" }
            Restart-VMHostService -HostService $srv -Confirm:$False -ErrorAction Continue

             while ((-not $VIAccount) -and ($RetryCount -le 6))
            {
                    Write-Host "Adding $_"
                    $VIAccount = Get-VIAccount -Server $esxi -Domain "IKT-Fag" -User $User -ErrorAction Stop
                    New-VIPermission -Principal $VIAccount -Role "Admin" -Entity $VMHost -ErrorAction Stop
            <#
                try 
                {
                    Write-Host "Adding $_"
                    $VIAccount = Get-VIAccount -Server $esxi -Domain "IKT-Fag" -User $User -ErrorAction Stop
                    New-VIPermission -Principal $VIAccount -Role "Admin" -Entity $VMHost -ErrorAction Stop
                }
                catch 
                {
                    Write-Warning "Permissions failed, trying again $RetryCount"
                    $VIAccount = $Null
                    Start-Sleep -Seconds 5
                    $RetryCount += 1
                }
                #>
            } #While
        }
        <#
        
        #>

        #$esxi
        #$Group
        "----------------------"

        Disconnect-VIServer * -Confirm:$False
        
    }




}

$Cred = Get-Credential

Set-ESXiHostGroupRights -Cred $Cred