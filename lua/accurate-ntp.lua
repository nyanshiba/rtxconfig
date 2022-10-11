-- DHCPv6で降ってきたNGNのNTPサーバリストを取得
function get_dhcpv6_ntp()
    local rtn, str = rt.command('show status ipv6 dhcp')
    return {string.match(str, /SNTP\sserver\[\d\]:\s([\w:]+)\s+/g)}
end
ntptbl = get_dhcpv6_ntp()
-- table.insert(ntptbl, '2404:1a8:1102::c')

-- 複数のNTPサーバで時刻合わせする関数
function accur_ntpdate(tbl)
    local result = {}
    for i, v in ipairs(tbl) do
        -- 時刻合わせの直前にsleepを噛ますとよいかも？
        rt.sleep(1)
        local rtn, str = rt.command($'ntpdate ${v}')
        table.insert(result, string.match(str, '([+-]%d)second'))
    end
    return table.concat(result)
end

-- 2つのNTPサーバとの時刻合わせ結果が+0になるまで合わせなおす
while (timediff ~= '+0+0') do
    timediff = accur_ntpdate(ntptbl)
    print(timediff)
end
