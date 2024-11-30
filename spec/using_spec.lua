local assert            = require "luassert"
local assert_eq         = assert.equal
local assert_has_error  = assert.has_error

local math_sin          = math.sin
local string_sub        = string.sub
local setmetatable      = setmetatable
local rawget            = rawget


describe("using.lua", function()
    local use, table_use, table_use_self

    setup(function()
        local using = require "using"
        use             = using.use
        table_use       = using.table_use
        table_use_self  = using.table_use_self
    end)

    teardown(function()
        use             = nil
        table_use       = nil
        table_use_self  = nil
    end)


    describe("use", function()
        it("works", function()
            local function foo()
                use(math, string)
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
    
    
            local function baz(t, e)
                use(t)
                assert_eq(e.x, x)
                assert_eq(e.y, y)
            end
    
            local function baz2(t, e)
                baz(t, e)
                assert_eq(nil, x)
                assert_eq(nil, y)
            end
    
            local t1 = { x = 3, y = -2 }
            local t2 = { x = 42, y = 69 }
            baz2(t1, t1)
            baz2(t2, t2)
        end)

        it("respects metatable __index", function()
            local function baz(t, e)
                use(t)
                assert_eq(e.x, x)
                assert_eq(e.y, y)
                assert_eq(42, __magic__)
            end
    
            local mt = getmetatable(getfenv(baz))
            local _index = mt and mt.__index
            setfenv(baz, setmetatable({}, {
                __index = function(t, k)
                    if k == "__magic__" then return 42 end
                    if _index then return _index(t, k) end
                    return rawget(t, k)
                end,
                __newindex = mt.__newindex
            }))

            local function baz2(t, e)
                baz(t, e)
                assert_eq(nil, x)
                assert_eq(nil, y)
                assert_eq(nil, __magic__)
            end
    
            local t1 = { x = 3, y = -2 }
            local t2 = { x = 42, y = 69 }
            baz2(t1, t1)
            baz2(t2, t2)
        end)

        it("errors on non-table arguments", function()
            assert_has_error(function()
                use(42)
            end, "expected table, got number (42) (1)")
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

                assert_eq(1, entity.x)
                assert_eq(2, entity.y)
                assert_eq(-3, entity.z)
            end

            local function bar()
                local entity    = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use(entity, entity.pos)
        
                assert_eq(1, entity.x)
                assert_eq(2, entity.y)
                assert_eq(-3, entity.z)
            end

            foo()
            bar()
        end)

        it("respects metatable __index", function()
            local obj = setmetatable({}, {
                __index = function(t, k)
                    if k == "__magic__" then return 42 end
                    return rawget(t, k)
                end
            })
            local xs = { x0 = 1, x1 = -3 }
            table_use(obj, xs)

            assert_eq(1, obj.x0)
            assert_eq(-3, obj.x1)
            assert_eq(42, obj.__magic__)
        end)

        it("errors on non-table arguments", function()
            assert_has_error(function()
                local entity = { type = "zombie" }
                table_use(entity, 42)
            end, "expected table, got number (42) (1)")
        end)
    
        it("errors on duplicate keys", function()
            assert_has_error(function()
                local entity = { type = "zombie" }
                local pos = { x = 1, y = 2, z = -3 }
                local xs = { x = 1 }
                table_use(entity, pos, xs)
            end, "duplicate key 'x'")
        end)
    end)


    describe("table_use_self", function()
        it("works", function()
            local entity = {
                type = "zombie",
                pos = { x = 1, y = 2, z = -3 },
                xs = { x0 = -1, x1 = 7 }
            }
            table_use_self(entity, "pos", "xs")
    
            assert_eq(1, entity.x)
            assert_eq(2, entity.y)
            assert_eq(-3, entity.z)
    
            assert_eq(-1, entity.x0)
            assert_eq(7, entity.x1)
        end)

        it("respects metatable __index", function()
            local obj = setmetatable({
                 xs = { x0 = 1, x1 = -3 }
            }, {
                __index = function(t, k)
                    if k == "__magic__" then return 42 end
                    return rawget(t, k)
                end
            })
            table_use_self(obj, "xs")

            assert_eq(1, obj.x0)
            assert_eq(-3, obj.x1)
            assert_eq(42, obj.__magic__)
        end)

        it("errors on non-table arguments", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 },
                    health = 42
                }
                table_use_self(entity, "health")
            end, "expected table, got number (42) (1)")
        end)
    
        it("errors on duplicate keys", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 },
                    xs = { x = 0 }
                }
                table_use_self(entity, "pos", "xs")
            end, "duplicate key 'x'")
        end)

        it("errors on duplicate included names", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use_self(entity, "pos", "pos")
            end, "duplicate included name 'pos'")
        end)

        it("errors on non-string included names", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use_self(entity, 42)
            end, "expected string, got number")
        end)

        it("errors on undefined included names", function()
            assert_has_error(function()
                local entity = {
                    type = "zombie",
                    pos = { x = 1, y = 2, z = -3 }
                }
                table_use_self(entity, "xs")
            end, "included name 'xs' not found")
        end)
    end)
end)