local table_getn       = table.getn
local string_format    = string.format
local pairs            = pairs
local ipairs           = ipairs
local type             = type
local getmetatable     = getmetatable
local setmetatable     = setmetatable
local getfenv          = getfenv
local setfenv          = setfenv
local rawget           = rawget
local error            = error
local tostring         = tostring


local function copy(...)
    local r = {}
    local xs = {...}
    local n = table_getn(xs)
    for i = 1, n do
        local x = xs[i]
        if x ~= nil then
            for k, v in pairs(x) do r[k] = v end
        end
    end
    return r
end


local function copy_into(dst, src)
    for k, v in pairs(src) do dst[k] = v end
end


local function check_input_tables(srcs)
    local ks = {}
    for i, src in ipairs(srcs) do
        if type(src) ~= "table" then
            error(string_format("expected table, got %s (%s) (%d)", type(src), tostring(src), i))
        end
        
        for k, _ in pairs(src) do
            if ks[k] then
                error(string_format("duplicate key '%s'", tostring(k)))
            end
            ks[k] = true
        end
    end
end


local function make_provider_metatable(tab, vals)
    local mt     = getmetatable(tag)
    local _index = mt and mt.__index
    return copy(mt, {
        __index = function(t, k)
            if vals[k] then return vals[k] end
            if _index then return _index(tab, k) end
            return rawget(tab, k)
        end
    })
end


local function make_provider(getdst, setmt)
    local patched = setmetatable({}, { __mode = "k" })
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

        for _, src in ipairs(srcs) do
            copy_into(vals, src)
        end
    end
end


local provide_in_table = make_provider(
    function(idst) return idst end,
    function(_, dst, mt)
        setmetatable(dst, mt)
        return dst
    end
)


local provide_in_fenv = make_provider(
    -- 3, not 4, because (i think) this function gets turned into a tailcall
    function(_) return getfenv(3) end,
    function(_, _, mt)
        local nfenv = setmetatable({}, mt)
        setfenv(4, nfenv)
        return nfenv
    end
)


local exports = {}

function exports.use(...)
    provide_in_fenv(nil, ...)
end

exports.table_use = provide_in_table

function exports.table_use_self(t, ...)
    local names = {...}
    local vals = {}
    for _, name in ipairs(names) do
        local v = t[name]
        assert(type(v) ~= nil) -- TODO
        vals[#vals+1] = v
    end
    provide_in_table(t, unpack(vals))
end

return exports