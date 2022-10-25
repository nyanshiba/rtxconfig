-- nslookupしてtableで返す関数
function lookup(host)
    local rtn, str = rt.command($'nslookup ${host}')
    if rtn then
        -- 少なくともAレコードはNOERROR
        return str:split(/\r?\n/)
    else
        -- A/AAAA共に否定応答
        return '', ''
    end
end

-- 最後のコマンドライン引数が数値ならdns staticのTTLと解釈し、指定されていなければ86400秒とする
if not arg[#arg]:match(/^\d+$/) then
    table.insert(arg, 86400)
end
ttl = arg[#arg]

-- 一時的にリカーシブDNSのキャッシュを無効化
rt.command('dns cache use off')

-- コマンドライン引数のFQDNを受け取る
for i = 1, #arg - 1 do
    -- 名前解決
    local a, aaaa = lookup(arg[i])

    local command = {}

    -- Aレコードがあれば設定を追加
    if a ~= '' then
        -- A
        -- 既にDNSシンクホール設定があれば削除
        if a:match(/0.0.0.0|192.168.100.1/) then
            table.insert(command, $'no dns static a ${arg[i]} ${a}')
        else
            table.insert(command, $'dns static a ${arg[i]} 0.0.0.0 ttl=${ttl}')
        end

        -- AAAA
        if aaaa:match(/^(::|fdca::1)$/) then
            table.insert(command, $'no dns static aaaa ${arg[i]} ${aaaa}')
        elseif aaaa ~= '' then
            table.insert(command, $'dns static aaaa ${arg[i]} :: ttl=${ttl}')
        -- AAAAレコードがなくても、(想定される)eTLD+1でなければTTLに明示しつつ設定を追加
        elseif not arg[i]:match(/^[\w-]+\.(co.jp|co.uk|ne.jp|or.jp|net.in|googleapis.com|appspot.com|dyndns.org|duckdns.org|ddns.net|cloudfront.net|ap-northeast-1.elasticbeanstalk.com|awsglobalaccelerator.com|elasticbeanstalk.com|s3-ap-northeast-1.amazonaws.com|s3.amazonaws.com|s3.dualstack.ap-northeast-1.amazonaws.com|s3.dualstack.ap-southeast-1.amazonaws.com|s3.eu-west-2.amazonaws.com|us-east-1.amazonaws.com|us-west-2.elasticbeanstalk.com|\w+)$/) then
            table.insert(command, $'dns static aaaa ${arg[i]} :: ttl=' .. ttl + 6)
        end
    end

    -- コンソールにconfigを返しつつ実行
    for j, v in ipairs(command) do
        print(v)
        rt.command(v)
    end
end

rt.command('dns cache use on')
