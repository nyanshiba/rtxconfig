-- 該当したら切断するハズレNNI/NTEブラックリスト (show status pp NUM の PP IP Address Remote)
ntetbl = {
    '192.0.2.37',
    '192.0.2.38',
    '192.0.2.40',
    '198.51.100.74',
    '198.51.100.69',
    '198.51.100.102',
    '203.0.113.71',
    '203.0.113.72',
    '203.0.113.73'
}

-- 電源喪失直後に双方、またはNTEガチャの最中で継っていないセッションがある場合、優先してガチャする
function get_pp_status(peer_num)
    local rtn, str = rt.command($'show status pp ${peer_num}')
    return string.match(str, /(IPCP.+),/)
end

-- PPPoEセッションが2つあることを想定している(フレッツのデフォルトセッション数)
for i = 1, 2 do
    if not(get_pp_status(i)) then
        peer_num = i
        break
    end
end

-- 2つのPPPoEセッションが継っている場合、ランダムにガチャする
if not(peer_num) then
    math.randomseed(os.time())
    peer_num = math.random(2)
end

-- PPPoEを切断したままにする関数
function pp_disconnect()
    rt.command($'pp disable ${peer_num}')
    rt.command($'disconnect pp ${peer_num}')
    -- IPマスカレードを行うNATディスクリプタ番号はPP 1なら1000, PP 2なら2000とする
    rt.command($'clear nat descriptor dynamic ${peer_num}000')
end

-- PPPoEを有効にし、接続を試みる関数
function pp_connect()
    rt.command($'pp enable ${peer_num}')
    rt.command($'connect pp ${peer_num}')
    rt.sleep(10)
    local rtn, str = rt.command($'show status pp ${peer_num}')
    return string.match(str, /Remote:\\s([\\d.]+)/)
end

-- (ISP側のレート制限を超えて)接続失敗したら、切断状態に戻す(次のscheduleでリトライする)
nte = pp_connect()
if not(nte) then
    pp_disconnect()
else
    -- NTEブラックリストと比較して、該当すれば切断する
    for i, v in ipairs(ntetbl) do
        if nte == v then
            pp_disconnect()
            break
        end
    end
end
