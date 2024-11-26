local function copy(...)
    local r = {}
    local xs = {...}
    local n = table.getn(xs)
    for i = 1, n do
        local x = xs[i]
        if x ~= nil then
            for k, v in pairs(x) do r[k] = v end
        end
    end
    return r
end

local patched_fenvs = setmetatable({}, { __mode = "k" })
return function(...)            
    local fenv = getfenv(2)
    local vals = patched_fenvs[fenv]

    if not vals then
        vals = {}
        
        local mt     = getmetatable(fenv)
        local _index = mt and mt.__index
        local nfenv = setmetatable({}, copy(mt, {
            __index = function(t, k)
                if vals[k] then return vals[k] end
                if _index then return _index(fenv, k) end
                return rawget(fenv, k)
            end
        }))

        patched_fenvs[nfenv] = vals
        setfenv(2, nfenv)
    end

    local srcs = {...}
    local ks   = {}
    for i, src in ipairs(srcs) do
        if type(src) ~= "table" then
            error(string.format("expected table, got %s (%s) (%d)", type(src), tostring(src), i))
        end
        
        for k, v in pairs(src) do
            if ks[k] then
                error(string.format("duplicate key '%s'", tostring(k)))
            end

            ks[k] = true
            vals[k] = v
        end
    end
end