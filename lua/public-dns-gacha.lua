-- (ICMP Echo Replyが返ってくる)DNSサーバのリスト
tbl = {
    -- OpenDNS
    -- https://en.wikipedia.org/wiki/OpenDNS#DNS
    '208.67.222.222',
    '208.67.220.220',
    '208.67.222.123',
    '208.67.220.123',
    '208.67.222.2',
    '208.67.220.2',
    '2620:119:35::35',
    '2620:119:53::53',
    '2620:119:35::123',
    '2620:119:53::123',
    '2620:0:ccc::2',
    '2620:0:ccd::2'
}

-- ICMPでRTTを計測し、90パーセンタイルを返す関数
function measure_rtt(cdn)
    -- ドメインはIPv4を計測する(Happy EyeballsでIPv4が優先されたときを想定)
    if string.find(cdn, ':') == nil then
        rtn, str = rt.command($'ping -c 10 -w 5.1 ${cdn}')
    else
        rtn, str = rt.command($'ping6 -c 10 -w 5.1 ${cdn}')
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

    rt.syslog('info', $'${cdn} RTT min/avg/max/percentile: ${rttsum}/${pctl} ms')

    -- 平均値も最大値もアテにならないので、90パーセンタイル(もどき)で回線品質を評価する
    return pctl
end


for i, v in ipairs(tbl) do
    local rtt = measure_rtt(v)
    -- 最初のDNSサーバを初期値とし、前の計測より小さいRTTなら記録を更新する
    if i == 1 or rtt < fast_rtt then
        fast_rtt = rtt
        fast_ip = v
    end
end
-- DNSサーバを設定する。通常の用途ではedns=onがよい
-- dns server select a/aaaa/mx etc.より優先度が低いdns serverコマンドにOpenDNSを設定することで、AppleデバイスからのHTTPS RRの問い合わせにNOERROR, NOANSWERを返すことができる
rt.command($'dns server ${fast_ip} edns=off')
