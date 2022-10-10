-- PP IP Address Remoteを取得する関数
function get_pp_remote(peer_num)
    local rtn, str = rt.command($'show status pp ${peer_num}')
    return string.match(str, /Remote:\s([\d.]+)/)
end

-- ping先
tbl = {
    -- IPv6のインターネット区間
    '2.au.download.windowsupdate.com',

    -- IPv6のNGN網内 (サービス情報サイト)
    'www3.syutoken-speed.flets-east.jp',
    'www1.syutoken-speed.flets-east.jp',

    -- IPv4のインターネット区間
    '1.1.1.1', -- PP 1 static route
    '1.1.1.2', -- PP 2

    -- IPv4のNGN網内
    get_pp_remote(1), -- PP 1 temporary route
    get_pp_remote(2) -- PP 2
}

-- IPv4のソースアドレス(グローバルIPアドレス)を取得する関数
function get_ip_route(host)
    local rtn, str = rt.command($'show ip route ${host}')
    local peer_num = string.match(str, /PP\[0(\d)]/)
    local rtn, str = rt.command($'show status pp ${peer_num}')
    return string.match(str, /Local:\s([\d.]+)/)
end

-- ICMPでRTTを計測し、syslogに出力する関数
function measure_rtt(host)
    -- アルファベットが含まれるIPv6アドレスまたはFQDNはping6で計測
    if string.find(host, '[a-z]') == nil then
        rtn, str = rt.command($'ping -c 10 -w 1 ${host}')
        -- ipinfoに飛べる形式でログ出力する
        host = $'${host} (https://ipinfo.io/${get_ip_route(host)})'
    else
        rtn, str = rt.command($'ping6 -c 10 -w 1 ${host}')
    end
    -- min/avg/max
    local rttsum = string.match(str, /=\s([\d.\/]+)\s/)

    -- 90パーセンタイル(もどき)
    local rttlist = {}
    string.gsub(str, /.*=(\d+)\.(\d+).*/,
        function (a, b)
            table.insert(rttlist, tonumber(a..b))
        end)
    table.sort(rttlist)
    local pctl = rttlist[#rttlist - 1]

    rt.syslog('info', $'${host} RTT min/avg/max/percentile: ${rttsum}/${pctl} ms')
end

-- pingリストを舐める
for i, v in ipairs(tbl) do
    measure_rtt(v)
end
