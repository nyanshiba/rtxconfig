-- ベンチマークに使う頻出ドメインリスト。syslogから探すとよいが、静的DNSレコードは除くべき
-- os.difftimeがミリ秒単位で測れないので、秒単位の差がつく程度のクエリ量がよい
fqdntbl = { 'iphone-ld.apple.com','tpop-api.twitter.com','www3.nhk.or.jp','connectivitycheck.gstatic.com','discord.com','ctldl.windowsupdate.com','imap01.au.com','proxsee.pscp.tv','i.ytimg.com','www.youtube.com','r3.o.lencr.org','config.edge.skype.com','www.bing.com','cdnjs.cloudflare.com','scrootca1.ocsp.secomtrust.net','b.st-hatena.com','star.c10r.facebook.com','cdn.jsdelivr.net','na.albtls.t.co','code.jquery.com','ipv4only.arpa' }

-- (ICMPに返答しない)DNSサーバのリスト
-- IPCPで降ってきたISPのIPv4 優先/代替DNSサーバを取得する関数
function get_ipcp_dns(peer_num)
    local rtn, str = rt.command($'show status pp ${peer_num}')
    return {string.match(str, /DNS\(([\d.]+)/g)}
end
-- DHCPv6で降ってきたNGNのIPv6 優先/代替DNSサーバを取得する関数
function get_dhcpv6_dns()
    local rtn, str = rt.command('show status ipv6 dhcp')
    return {string.match(str, /DNS\sserver\[\d\]:\s([\w:]+)\s+/g)}
end

-- クエリ時間を計測する関数
function measure_qtime(peer_num, dns)
    -- 一時的にAレコードの問い合わせを任意のDNSに向ける。10番より前に外せないdns server selectを、後にdns server select a/aaaa/mx .が書かれている前提
    rt.command($'dns server select 15 ${dns} edns=on a .')
    -- alias @isp11, @isp12を実行して、マルチホーム環境で一時的にDNSのパケットがPP 1, 2へルーティングされるようip route default gatewayを切り替える
    rt.command($'@isp1${peer_num}')

    -- 一時的にレカーシブDNSのキャッシュを無効化
    rt.command('dns cache use off')
    local t1 = os.clock()
    do
        for i, v in ipairs(fqdntbl) do
            rt.socket.dns.toip(v)
        end
    end
    local t2 = os.clock()
    local qtime = os.difftime(t2, t1)
    rt.command('dns cache use on')

    rt.command($'no dns server select 15')
    -- alias @isp10を実行して、マルチホーム環境でip route default gatewayをロードバランスする設定に戻す
    rt.command('@isp10')

    rt.syslog('info', $'Query time: PP${peer_num} ${dns} ${qtime}sec')
    return qtime
end

-- 逆NATを削除する関数
function no_reverse_nat(peer_num)
    -- 静的NATエントリidは1, 2を使う
    for i = 1, 2 do
        -- PP "1"のNATディスクリプタ番号は、IPマスカレードが"1"000, 逆NATは100"2"とする
        -- ip pp nat descriptor 1000 reverse 1002
        rt.command($'no nat descriptor static ${peer_num}002 ${i}')
    end
end

-- 逆NATを設定する関数
function set_reverse_nat(peer_num, dummy_dns, fast_dns)
    -- ソースアドレスがfast_dnsな問い合わせがタイムアウトしないよう、あべこべの逆NAT設定も入れる
    rt.command($'nat descriptor static ${peer_num}002 1 ${dummy_dns}=${fast_dns} 1')
    rt.command($'nat descriptor static ${peer_num}002 2 ${fast_dns}=${dummy_dns} 1')
end

-- AAAAレコードの問い合わせに使うNGNのDNSサーバを選ぶ
for i, v in ipairs(get_dhcpv6_dns()) do
    local qtime = measure_qtime(0, v)
    -- 初期値を優先DNSサーバとし、RTTがより小さければ代替を選ぶ
    if i == 1 or qtime < fast_qtime_v6 then
        fast_qtime_v6 = qtime
        fast_dns_v6 = v
    end
end
rt.command($'dns server select 25 ${fast_dns_v6} edns=on aaaa .')

-- Aレコードの問い合わせに使うISPのDNSサーバを選ぶ
for i = 1, 2 do
    -- 計測・設定更新に邪魔な以前の逆NAT設定を削除
    no_reverse_nat(i)

    -- IPv4 DNSをベンチマーク
    for j, v in ipairs(get_ipcp_dns(i)) do
        local qtime = measure_qtime(i, v)
        -- 初期値を優先DNSサーバとし、RTTが同等以下であれば代替を選ぶ
        if j == 1 or qtime <= fast_qtime then
            fast_qtime = qtime
            fast_dns = v
        end
    end

    -- NGNのDNSの方が速ければAレコードの問い合わせに使う(PPPoEの輻輳・パケロス増加時を想定)
    if fast_qtime_v6 < fast_qtime then
        rt.command($'dns server select ${25 + i} ${fast_dns_v6} edns=on a .')
    else
        -- 逆NATにより1.1.1.1への問い合わせが最もRTTが優れたISPのDNSに向くよう、静的NATエントリを追加する例
        set_reverse_nat(i, '1.1.1.1', fast_dns)
        rt.command($'dns server select ${25 + i} 1.1.1.1 edns=on a . restrict pp ${i}')
    end
end
