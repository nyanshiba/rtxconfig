-- ICMPでRTTを計測し、90パーセンタイルを返す関数
function measure_rtt(host, count, wait)
    -- ドメインはIPv4を計測する(Happy EyeballsでIPv4が優先されたときを想定)
    local count = count or 10
    local wait = wait or 1
    if string.find(host, ':') == nil then
        rtn, str = rt.command($'ping -c ${count} -f -w ${wait} ${host}')
    else
        rtn, str = rt.command($'ping6 -c ${count} -w ${wait} ${host}')
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

    -- 平均値も最大値もアテにならないので、90パーセンタイル(もどき)で回線品質を評価する
    return rttsum, pctl
end

-- CDNのRTTを比較する関数
function compare_rtt(hosts)
    -- 同一IPのCDN一括指定に対応
    fqdn = hosts[1][1]

    -- 静的DNSレコードを削除
    rt.command($'no dns static a ${fqdn}')
    rt.command($'no dns static aaaa ${fqdn}')

    for i, v in ipairs(hosts) do
        local host
        if i == 1 then
            host = fqdn
        else
            host = v
        end
        local rttsum, rtt = measure_rtt(host)
        rt.syslog('info', $'${host} RTT min/avg/max/percentile: ${rttsum}/${rtt} ms')

        -- 最初に書かれたドメインを初期値とし、前の計測と同等以下のRTTなら記録を更新する
        if rtt and i == 1 or rtt and rtt < fast_rtt then
            fast_rtt = rtt
            fast_cdn = host
        end
    end

    -- CDNガチャの結果、何もしないのが最適であれば静的DNSレコードを削除
    if fast_cdn ~= fqdn then
        for i, v in ipairs(hosts[1]) do
            -- 最もRTTが優れていたCDNを静的DNSレコードに追加
            -- アプリケーションの最小TTLであろう60秒にしておく。キャッシュポイズニング対策とは無関係で、configの一覧性のため
            -- 構文エラーを期待して条件分岐を省く！
            rt.command($'dns static a ${v} ${fast_cdn} ttl=60')
            rt.command($'dns static aaaa ${v} ${fast_cdn} ttl=60')
        end
    end
end

function generate_google_ip(fqdntbl, prefix, suffix)
    local hosts = { fqdntbl }
    -- 0x01 - 0x30
    for i = 1, 48 do
    -- for i = 28, 39 do
        local ip = prefix .. string.format('%02x', i) .. suffix

        rttsum, rtt = measure_rtt(ip, 1, '0.1')
        if rttsum then
            table.insert(hosts, ip)
        end
    end

    return hosts
end

-- 一時的にDNSリカーシブサーバのキャッシュを無効化
rt.command('clear dns cache')

-- Twitter画像サーバ
compare_rtt({
    {'pbs.twimg.com'}, -- 最初にドメインを記述する
    '2600:1480:4000:e5::', -- 後にdig等で取得したIPアドレスを記述
    '2600:1480:3000:e5::', -- pbs-ak.twimg.com
    '2a04:4e42:15::159', -- dualstack.twimg.twitter.map.fastly.net
    '2a04:4e42:1a::159',
    '2a04:4e42:8c::159'
})
-- Twitter動画サーバ
compare_rtt({
    {'video.twimg.com'}, -- EdgeCast, Akamai, Fastly, etc...
    '2600:1480:4000:e4::', -- video-ak.twimg.com
    '2600:1480:3000:e4::',
    '2a04:4e42:15::158', -- dualstack.video.twitter.map.fastly.net
    '2a04:4e42:1a::158',
    '2a04:4e42:8c::158'
})
-- Google
compare_rtt(
    generate_google_ip(
        {
            'fonts.gstatic.com',
            'clientservices.googleapis.com',
            'crashlyticsreports-pa.googleapis.com',
            'ocsp.pki.goog',
            'www.google.co.jp'
        },
        '2404:6800:4004:8', '::2003'
    )
)
