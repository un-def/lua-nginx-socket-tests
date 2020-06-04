local cjson = require('cjson')

local _M = {}

_M.nargs = function(...)
    return select('#', ...), ...
end

_M.repr = function(...)
    local tbl = {...}
    for i = 1, select('#', ...) do
        if tbl[i] == nil then
            tbl[i] = cjson.null
        end
    end
    return cjson.encode(tbl)
end

return _M
