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


local function copy_into(dst, src)
    for k, v in pairs(src) do dst[k] = v end
end


local function copy(...)
    local r = {}
    local xs = {...}
    for i = 1, #xs do
        local x = xs[i]
        if x ~= nil then
            copy_into(r, x)
        end
    end
    return r
end


local function check_string_or_table(x)
    local t = type(x)
    if t ~= "string" and t ~= "table" then
        error(string_format("expected string or table, got %s (%s)", type(x), tostring(x)))
    end
end


local function check_duplicate_keys(srcs)
    local ks = {}
    for _, src in ipairs(srcs) do
        for k, _ in pairs(src) do
            if ks[k] then
                error(string_format("duplicate key '%s'", tostring(k)))
            end
            ks[k] = true
        end
    end
end


local function make_provider_metatable(mt, vals)
    local _index = rawget(mt or {}, "__index")
    return copy(mt, {
        __index = function(t, k)
            -- NOTE TODO: should this case be first or last? (or in the middle?)
            if vals[k] then return vals[k] end
           
            local v = rawget(t, k)
            if v ~= nil then return v end

            if type(_index) == "function" then return _index(t, k) end
            if type(_index) == "table" then return _index[k] end

            return nil
        end
    })
end


local function getsrc(dst, x)
    check_string_or_table(x)

    if type(x) == "string" then
        local v = dst[x]
        if v == nil then
            error(string_format("included name '%s' not found", x))
        end
        check_string_or_table(v)
        return v
    end

    return x
end


local function make_provider(getdst, setmt)
    local patched = setmetatable({}, { __mode = "k" })
    return function(idst, ...)
        local dst  = getdst(idst)
        if type(dst) ~= "table" then
            error(string_format("expected table, got %s (%s) from %s", type(dst), tostring(dst), tostring(idst)))
        end
        
        local srcs = {}
        for _, x in ipairs({...}) do
            srcs[#srcs+1] = getsrc(dst, x)
        end
        check_duplicate_keys(srcs)

        local vals = patched[dst]
        if not vals then
            vals = {}
            local mt = make_provider_metatable(getmetatable(dst), vals)
            patched[setmt(idst, dst, mt)] = vals
        end

        for _, src in ipairs(srcs) do
            copy_into(vals, src)
        end
    end
end


local provide_in_fenv = make_provider(
    -- 3, not 4, because (i think) this function gets turned into a tailcall
    function(_) return getfenv(3) end,
    function(_, _, mt)
        local nfenv = setmetatable({}, mt)
        setfenv(4, nfenv)
        return nfenv
    end
)


local provide_in_table = make_provider(
    function(idst) return idst end,
    function(_, dst, mt)
        setmetatable(dst, mt)
        return dst
    end
)


return {
    use                         = function(...) provide_in_fenv(nil, ...) end,
    table_use                   = provide_in_table,
    util        = {
        copy_into               = copy_into,
        copy                    = copy,
        make_provider_metatable = make_provider_metatable
    }
}