local _table_getn       = table.getn
local _pairs            = pairs
local _ipairs           = ipairs
local _type             = type
local _getmetatable     = getmetatable
local _setmetatable     = setmetatable
local _getfenv          = getfenv
local _setfenv          = setfenv
local _rawget           = rawget
local _error            = error
local _tostring         = tostring
local _string_format    = string.format


local function copy(...)
    local r = {}
    local xs = {...}
    local n = _table_getn(xs)
    for i = 1, n do
        local x = xs[i]
        if x ~= nil then
            for k, v in _pairs(x) do r[k] = v end
        end
    end
    return r
end


local function copy_into(dst, src)
    for k, v in _pairs(src) do dst[k] = v end
end


local function check_input_tables(srcs)
    local ks = {}
    for i, src in _ipairs(srcs) do
        if _type(src) ~= "table" then
            _error(_string_format("expected table, got %s (%s) (%d)", _type(src), _tostring(src), i))
        end
        
        for k, v in _pairs(src) do
            if ks[k] then
                _error(_string_format("duplicate key '%s'", _tostring(k)))
            end
            ks[k] = true
        end
    end
end


local function make_provider_metatable(tab, vals)
    local mt     = _getmetatable(tag)
    local _index = mt and mt.__index
    return copy(mt, {
        __index = function(t, k)
            if vals[k] then return vals[k] end
            if _index then return _index(tab, k) end
            return _rawget(tab, k)
        end
    })
end


local function make_provider(getdst, setmt)
    local patched = _setmetatable({}, { __mode = "k" })
    return function(idst, ...)
        local srcs = {...}
        check_input_tables(srcs)

        local dst  = getdst(idst)
        local vals = patched[dst]

        if not vals then
            vals = {}
            local mt = make_provider_metatable(dst, vals)
            patched[setmt(idst, dst, mt)] = vals
        end

        for _, src in _ipairs(srcs) do
            copy_into(vals, src)
        end
    end
end


local provide_in_table = make_provider(
    function(idst) return idst end,
    function(_, dst, mt)
        _setmetatable(dst, mt)
        return dst
    end
)


local provide_in_fenv = make_provider(
    -- 3, not 4, because (i think) this function gets turned into a tailcall 
    function(_) return _getfenv(3) end,
    function(_, _, mt)
        local nfenv = _setmetatable({}, mt)
        _setfenv(4, nfenv)
        return nfenv
    end
)


return {
    use         = function(...) provide_in_fenv(nil, unpack({...})) end,
    table_use   = provide_in_table
}