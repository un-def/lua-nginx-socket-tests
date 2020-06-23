local cjson = require('cjson')

local TEST_SOCKET_HOST = '127.0.0.1'

local _M = {}

local repr = function(...)
    local tbl = {...}
    for i = 1, select('#', ...) do
        local value = tbl[i]
        if value == nil then
            tbl[i] = cjson.null
        elseif type(value) == 'function' then
            tbl[i] = '<function>'
        end
    end
    return cjson.encode(tbl)
end

_M.repr = repr

_M.rrepr = function(...)
    return repr(...), ...
end

local tcp_connect = function(sock, host, port, options)
    host = host or TEST_SOCKET_HOST
    port = port or os.getenv('TEST_SOCKET_PORT')
    return assert(sock:connect(host, port, options))
end

_M.tcp_connect = tcp_connect

_M.tcp = function(connected)
    local sock = assert(ngx.socket.tcp())
    if connected then
        tcp_connect(sock)
    end
    return sock
end

return _M
