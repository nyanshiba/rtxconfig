-- DOWNLOAD ボタンを押した時に実行する 例:
-- operation button function download execute lua sd1:/lua/switch-port-mirroring.lua

-- ポートミラーリングの有効無効を切り替える
rtn, str = rt.command($'show config')
if string.find(str, /lan\sport-mirroring\slan1/) == nil then
    rt.syslog('info', $'switch-port-mirroring.lua: Enabling port mirroring on lan1')
    rt.command('lan port-mirroring lan1 1 in 4 out 4')
else
    rt.syslog('info', $'switch-port-mirroring.lua: Disabling port mirroring on lan1')
    rt.command('no lan port-mirroring lan1')
end
