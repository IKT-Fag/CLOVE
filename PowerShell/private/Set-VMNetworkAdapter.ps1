$Hosts = @(1..9 | % {
    "172.16.0.$(100 + $_)"
})

$Hosts | % {
    $VM = Get-VM -Name "*$_*" -ErrorAction SilentlyContinue
    if (!($VM))
    {
        Write-Error "VM does not exist."
        return
    }

    $nic = Get-NetworkAdapter | Where Name -Like "10.0.*"
    Set-NetAdapter -
}