local assert            = require "luassert"
local assert_eq         = assert.equal
local assert_has_error  = assert.has_error

local describe          = describe
local setup             = setup
local teardown          = teardown
local it                = it

local table_getn        = table.getn
local pairs             = pairs
local type              = type
local getmetatable      = getmetatable
local setmetatable      = setmetatable
local getfenv           = getfenv
local setfenv           = setfenv
local rawget            = rawget


local function copy_into(dst, src)
    for k, v in pairs(src) do dst[k] = v end
end


local function copy(...)
    local r = {}
    local xs = {...}
    for i = 1, table_getn(xs) do
        local x = xs[i]
        if x ~= nil then
            copy_into(r, x)
        end
    end
    return r
end


local function assert_included(table, included)
    if type(included) == "string" then
        included = table[included]
    end
    
    for k, v in pairs(included) do
        assert_eq(v, table[k])
    end
end


describe("using.lua", function()
    local use, table_use, make_provider_metatable

    setup(function()
        local using                 = require "using"
        use                         = using.use
        table_use                   = using.table_use
        make_provider_metatable     = using.util.make_provider_metatable
    end)

    teardown(function()
        use                         = nil
        table_use                   = nil
        make_provider_metatable     = nil
    end)


    describe("use", function()
        it("works", function()
            local math_sin      = math.sin
            local string_sub    = string.sub

            local function foo()
                use(math, "string")
                assert_eq(math_sin, sin)
                assert_eq(string_sub, sub)
            end
    
            local function bar()
                foo()
                assert_eq(nil, sin)
                assert_eq(nil, sub)
            end
    
            bar()
            bar()
    
    
            local function baz(t)
                use(t)
                assert_included(getfenv(1), t)
            end
    
            local function baz2(t)
                baz(t)
                assert_eq(nil, x)
                assert_eq(nil, y)
            end
    
            baz2({ x = 3, y = -2 })
            baz2({ x = 42, y = 69 })
            assert_eq(nil, x)
            assert_eq(nil, y)
        end)

        it("respects __index metamethod", function()
            local function baz(t)
                use(t)
                assert_included(getfenv(1), t)
                assert_eq(42, __magic__)
            end
    
            local mt = make_provider_metatable(
                getmetatable(getfenv(baz)),
                { __magic__ = 42 }
            )
            setfenv(baz, setmetatable({}, mt))


            local function baz2(t)
                baz(t)
                assert_eq(nil, x)
                assert_eq(nil, y)
                assert_eq(nil, __magic__)
            end
    
            baz2({ x = 3, y = -2 })
            baz2({ x = 42, y = 69 })
            assert_eq(nil, x)
            assert_eq(nil, y)
        end)

        it("respects __index table", function()
            pending()
        end)

        it("errors on non-table arguments", function()
            assert_has_error(function()
                use(42)
            end, "expected string or table, got number (42)")
        end)
    
        it("errors on duplicate keys", function()
            assert_has_error(function()
                use({ x = 1 }, { x = 2 })
            end, "duplicate key 'x'")
        end)
    end)


    describe("table_use", function()
        it("works", function()
            local function foo()
                local pos       = { x = 1, y = 2, z = -3 }
                local entity    = { type = "zombie" }
                table_use(entity, pos)

                assert_included(entity, pos)
            end

            local function bar()
                local entity    = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use(entity, entity.pos)
        
                assert_included(entity, "pos")
            end

            local function baz()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 },
                    xs = { x0 = -1, x1 = 7 }
                }
                table_use(entity, "pos", entity.xs)
        
                assert_included(entity, "pos")
                assert_included(entity, "xs")
            end

            foo()
            bar()
            baz()
        end)

        it("respects __index metamethod", function()
            local function foo()
                local mt = make_provider_metatable(nil, { __magic__ = 42 })
                local obj = setmetatable({}, mt)
                local xs = { x0 = 1, x1 = -3 }
                table_use(obj, xs)

                assert_included(obj, xs)
                assert_eq(42, obj.__magic__)
            end

            local function bar()
                local mt = make_provider_metatable(nil, { __magic__ = 42 })
                local obj = setmetatable({
                    xs = { x0 = 1, x1 = -3 }
                }, mt)
                table_use(obj, "xs")
   
                assert_included(obj, "xs")
                assert_eq(42, obj.__magic__)
            end

            foo()
            bar()
        end)

        it("respects __index table", function()
            local oindex = {
                x = 4, z = -7, w = 6
            }
            local obj = setmetatable({
                x = 1, y = 2
            }, { __index = oindex })
            local xs = { x0 = "a", x1 = "b", w = "c" }
            table_use(obj, xs)

            assert_eq(1, obj.x)
            assert_eq(2, obj.y)
            assert_eq(-7, obj.z)
            assert_included(obj, xs)
        end)

        it("errors on non-table arguments", function()
            assert_has_error(function()
                table_use(42, { x = 1, y = -2 })
            end, "expected table, got number (42) from 42")

            assert_has_error(function()
                local entity = { type = "zombie" }
                table_use(entity, 42)
            end, "expected string or table, got number (42)")

            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 },
                    health = 42
                }
                table_use(entity, "health")
            end, "expected string or table, got number (42)")
        end)
    
        it("errors on duplicate keys", function()
            assert_has_error(function()
                local entity = { type = "zombie" }
                local pos = { x = 1, y = 2, z = -3 }
                local xs = { x = 1 }
                table_use(entity, pos, xs)
            end, "duplicate key 'x'")

            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 },
                    xs = { x = 0 }
                }
                table_use(entity, "pos", entity.xs)
            end, "duplicate key 'x'")
        end)

        it("errors on invalid included names", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use(entity, 42)
            end, "expected string or table, got number (42)")
        end)

        it("errors on undefined included names", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use(entity, "xs")
            end, "included name 'xs' not found")
        end)
    end)
end)