-- nslookupしてtableで返す関数
function lookup(host)
    local rtn, str = rt.command($'nslookup ${host}')
    return str:split(/\r?\n/)
end

-- 最後のコマンドライン引数が数値ならdns staticのTTLと解釈し、指定されていなければ86400秒とする
if not arg[#arg]:match(/^\d+$/) then
    table.insert(arg, 86400)
end
ttl = arg[#arg]

-- コマンドライン引数のドメインを受け取る
for i = 1, #arg - 1 do
    -- nslookup
    local a, aaaa = lookup(arg[i])

    local command = {}

    -- 既にDNSシンクホール設定があれば削除
    if a:match(/0.0.0.0|192.168.100.1/) then
        table.insert(command, $'no dns static a ${arg[i]} ${a}')
    -- Aレコードがあれば設定を追加
    elseif a ~= '' then
        table.insert(command, $'dns static a ${arg[i]} 0.0.0.0 ttl=${ttl}')
    end

    if aaaa:match(/^(::|fdca::1)$/) then
        table.insert(command, $'no dns static aaaa ${arg[i]} ${aaaa}')
    elseif aaaa ~= '' then
        table.insert(command, $'dns static aaaa ${arg[i]} :: ttl=${ttl}')
    -- AAAAレコードがなければ、TTLに明示しつつ設定を追加
    else
        table.insert(command, $'dns static aaaa ${arg[i]} :: ttl=' .. ttl + 6)
    end

    -- コンソールにconfigを返しつつ実行
    print('')
    for j, v in ipairs(command) do
        print(v)
        rt.command(v)
    end
end

-- 浸透を待たない
rt.command('clear dns cache')
