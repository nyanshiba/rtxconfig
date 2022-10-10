-- ほぼヤマハのrt.socket.udp()サンプルスクリプトそのまま http://www.rtpro.yamaha.co.jp/RT/docs/lua/rt_api.html#socket.udp
host = '192.168.100.1'
port = 514

udp = rt.socket.udp()
res, err = udp:setsockname(host, port)
if (err) then
  print('setsockname error(' .. err .. ')')
  udp:close()
  os.exit(1)
end

lhost, lport = udp:getsockname()
print('Bind to host:' .. lhost .. ' and port:' .. lport)

while 1 do
  dgram, ip, port = udp:receivefrom()
  if (dgram ~= nil) then
    -- WLXのログのうち、STAの接続要請, DFS, チャンネル自動選択をRTXのsyslogに流す http://www.rtpro.yamaha.co.jp/AP/docs/wlx212/log_reference.html
    if (string.match(dgram, /(0101|030|0502)/)) then
        rt.syslog('info', dgram .. ' from ' .. ip .. ':' .. port)
    end
  else
    print(ip)
    udp:close()
    os.exit(0)
  end
end
