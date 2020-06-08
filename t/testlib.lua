local cjson = require('cjson')

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

return _M
