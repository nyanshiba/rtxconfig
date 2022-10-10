-- 16進の疑似乱数を生成する関数
-- 目的はプライバシーではなく、DNSのRRLなどレート制限回避なのでこれでよい
math.randomseed(os.time())
function random_suffix(n)
    local r = math.random(n)
    return string.format('%x', r)
end

-- 無効化できないlifetime: INFINITYなIPv6アドレスが始点アドレスにならないよう範囲を制限する (基本的に::に近いIIDが優先される)
-- ipv6 source address selection rule prefix
suffix = {random_suffix(117)}

-- 下位48bitはそれぞれ0x0 - 0xffff(65535)の範囲で生成
for i = 2, 4 do
    table.insert(suffix, random_suffix(65535))
end

-- 現在設定されているIPv6アドレスを取得
rtn, str = rt.command('show ipv6 address lan1')
nosuffix = {string.match(str, /24(\\w+:){4}([\\w:]+)\\/64/g)}
-- 新たなIPv6アドレスを設定
rt.command($'ipv6 lan1 address ra-prefix@lan2::' .. table.concat(suffix, ':') .. '/64')
-- 前回設定したIPv6アドレスを削除
rt.command($'no ipv6 lan1 address ra-prefix@lan2::${nosuffix[2]}/64')
