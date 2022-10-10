-- ICMPでRTTを計測する関数
function measure_rtt(ip)
    local rtn, str = rt.command($'ping -c 10 -w 1 ${ip}')
    -- min/avg/max
    local rttsum = string.match(str, /=\\s([\\d.\\/]+)\\s/)

    -- 90パーセンタイル(もどき)
    local rttlist = {}
    string.gsub(str, /.*=(\\d+)\\.(\\d+).*/,
        function (a, b)
            table.insert(rttlist, tonumber(a..b))
        end)
    table.sort(rttlist)
    local pctl = rttlist[#rttlist - 1]

    rt.syslog('info', $'${ip} RTT min/avg/max/percentile: ${rttsum}/${pctl} ms')

    -- 平均値も最大値もアテにならないので、90パーセンタイル(もどき)で回線品質を評価する
    return pctl
end

-- PPPoEを切断したままにする関数
function pp_disconnect(peer_num)
    rt.command($'pp disable ${peer_num}')
    rt.command($'disconnect pp ${peer_num}')
    -- IPマスカレードを行うNATディスクリプタ番号はPP 1なら1000, PP 2なら2000とする
    rt.command($'clear nat descriptor dynamic ${peer_num}000') 
end

-- 2つのPPPoEセッションを比較して、RTTが悪い方を落としてnte-gacha.luaによる再ガチャを促す
-- それぞれのPPPoEセッションを使うようにstatic routeされている前提
if measure_rtt('1.1.1.1') > measure_rtt('1.1.1.2') then
    pp_disconnect(1)
else
    pp_disconnect(2)
end
