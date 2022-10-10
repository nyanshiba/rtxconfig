-- ICMPでRTTを計測し、90パーセンタイルを返す関数
function measure_rtt(cdn)
    -- ドメインはIPv4を計測する(Happy EyeballsでIPv4が優先されたときを想定)
    if string.find(cdn, ':') == nil then
        rtn, str = rt.command($'ping -c 10 -w 1 ${cdn}')
    else
        rtn, str = rt.command($'ping6 -c 10 -w 1 ${cdn}')
    end
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

    rt.syslog('info', $'${cdn} RTT min/avg/max/percentile: ${rttsum}/${pctl} ms')

    -- 平均値も最大値もアテにならないので、90パーセンタイル(もどき)で回線品質を評価する
    return pctl
end

-- CDNのRTTを比較する関数
function compare_rtt(tbl)
    for i, v in ipairs(tbl) do
        local rtt = measure_rtt(v)
        -- 最初に書かれたドメインを初期値とし、前の計測と同等以下のRTTなら記録を更新する
        if i == 1 or rtt <= fast_rtt then
            fast_rtt = rtt
            fast_cdn = v
        end
    end

    -- CDNガチャの結果、何もしないのが最適であれば静的DNSレコードを削除
    if fast_cdn == tbl[1] then
        rt.command($'no dns static aaaa ${tbl[1]}')
    else
        -- 最もRTTが優れていたCDNを静的DNSレコードに追加
        -- アプリケーションの最小TTLであろう60秒にしておく。キャッシュポイズニング対策とは無関係で、configの一覧性のため
        rt.command($'dns static aaaa ${tbl[1]} ${fast_cdn} ttl=60')
    end
end

-- Twitter画像サーバ
compare_rtt({
    'pbs.twimg.com', -- 最初にドメインを記述する
    '2600:1480:4000:e5::', -- 後にdig等で取得したIPアドレスを記述
    '2600:1480:3000:e5::', -- pbs-ak.twimg.com
    '2a04:4e42:15::159', -- dualstack.twimg.twitter.map.fastly.net
    '2a04:4e42:1a::159',
    '2a04:4e42:8c::159'
})
-- Twitter動画サーバ
compare_rtt({
    'video.twimg.com', -- EdgeCast, Akamai, Fastly, etc...
    '2600:1480:4000:e4::', -- video-ak.twimg.com
    '2600:1480:3000:e4::',
    '2a04:4e42:15::158', -- dualstack.video.twitter.map.fastly.net
    '2a04:4e42:1a::158',
    '2a04:4e42:8c::158'
})
