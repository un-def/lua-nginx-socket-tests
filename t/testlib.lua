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

_M.tcp = function()
    local sock = ngx.socket.tcp()
    assert(sock:connect(TEST_SOCKET_HOST, os.getenv('TEST_SOCKET_PORT')))
    return sock
end

return _M
