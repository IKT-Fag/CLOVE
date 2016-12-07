function Convert-NetmaskToWildcard($Netmask)
{
    $Netmask = $Netmask.split(".")
    $Col = ""
    foreach ($Part in $Netmask)
    {
        $Part = [Convert]::ToString($Part,2).PadLeft(8, '0')
        $PartCache = ""
        
        foreach ($Bit in [Char[]]$Part)
        {
            switch ($Bit)
            {
                "1" { $Bit = 0 }
                "0" { $Bit = 1 }
            }
            $PartCache += $Bit
        }
        $Col += "$PartCache."
    }

    $WildcardBin = ($Col.TrimEnd("."))

    $Col2 = ""
    foreach ($Part in ($Col.Split(".")))
    {
        if ($Part -eq "" -or $Part -eq $null) { continue }
        $Part = [Convert]::ToInt32($Part, 2)
        $Col2 += "$Part."
    }
    $Wildcard = $Col2.TrimEnd(".")

    [PSCustomObject]@{
        Wildcard = $Wildcard
        WildcardBinary = $WildcardBin
    }
}
