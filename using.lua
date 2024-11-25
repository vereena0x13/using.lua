return setmetatable({}, {
    __call = function(t, cfg)
        if rawget(_G, "using") ~= nil then error("using already defined") end

        local patched_fenvs = setmetatable({}, { __mode = "k" })
        local using = function(...)            
            local fenv   = getfenv(2)
            local vals   = patched_fenvs[fenv]

            if not vals then
                vals = {}
                
                local mt = getmetatable(fenv)
                local _index = mt and mt.__index
                local nfenv  = setmetatable({}, {
                    __index = function(t, k)
                        if vals[k] then return vals[k] end
                        if _index then return _index(fenv, k) end
                        return rawget(fenv, k)
                    end
                })

                patched_fenvs[nfenv] = vals
                setfenv(2, nfenv)
            end

            local srcs = {...}
            -- TODO: error upon duplicate keys within each src
            for _, src in ipairs(srcs) do
                if type(src) ~= "table" then error("expected table, got " .. type(src)) end
                for k, v in pairs(src) do
                    vals[k] = v
                end
            end
        end

        local sg = cfg and cfg["set_global"]
        if sg ~= false then rawset(_G, "using", using) end

        return using
    end
})