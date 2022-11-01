-- DOWNLOAD ボタンを押した時に実行する 例:
-- operation button function download execute lua sd1:/lua/switch-mirror-port.lua

-- 現在のキャプチャポート
rtn, str = rt.command($'show config')
current_capture_port = tonumber(string.match(str, /mirroring\slan1\s3\sin\s(\d)\s/))

-- キャプチャポートは2と4をトグルする
if current_capture_port == 4 then
    capture_port = 2
else
    capture_port = 4
end
-- ミラーポートは3番
rt.syslog('info', $'switch-mirror-port.lua: Switching capture port from ${current_capture_port} to ${capture_port}')
rt.command($'lan port-mirroring lan1 3 in ${capture_port} out ${capture_port}')

-- STATUS LEDの点滅でキャプチャポートを知らせる
led, str = rt.hw.open("status-led1")
if (led) then
    -- 100ミリ秒単位だよ
	led:blink(300, 300)
	rt.sleep(capture_port / 2)

	led:off()
	led:close()
end
