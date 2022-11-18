#!/usr/bin/env pwsh
#requires -version 7

# configure /etc/ntp.conf then /usr/sbin/ntpq --peers --width 1000 >> ntpq-peers.log
# ntpq --peersのログから、remote addressのある行を配列で取得
[string[]]$results = (Get-Content ./ntpq-peers.log) -split '\r?\n'| Where-Object { $_ -match "::" }
$restable = [System.Collections.ArrayList]::new()
&{
    foreach ($line in $results)
    {
        # 文字列な表を配列に
        $cell = $line -split "[\+\-\*\s]+"
        $script:restable += @([PSCustomObject]@{
            remote = $cell[1]
            delay = $cell[8]
            offset = $cell[9]
            jitter = $cell[10]
        })
    }
}

# delay, offset, jitter別に集計
foreach ($property in ($restable | Get-Member -MemberType NoteProperty | Where-Object Name -ne "remote").Name)
{
    New-Variable -Name $property -Value ([System.Collections.ArrayList]::new())

    # remote別に集計
    foreach ($remote in ($restable.remote | Sort-Object | Get-Unique))
    {
        &{
            # 
            $hoge = $restable | Where-Object remote -eq $remote | Measure-Object -Property $property -AllStats
            Add-Member -InputObject $hoge -Name remote -MemberType NoteProperty -Value $remote
            (Get-Variable -Name $property -ValueOnly).Add($hoge) > $null
        }
    }
    # 表をソートして表示
    $order = Read-Host "$property sort by [remote, StandardDeviation, Sum, Average, Maximum, Minimum]"
    (Get-Variable -Name $property -ValueOnly) | Sort-Object -Property $order | Format-Table -Property *
}
