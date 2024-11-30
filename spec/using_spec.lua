local assert = require "luassert"

local math_sin = math.sin
local string_sub = string.sub

describe("using", function()
    local using

    setup(function()
        using = require "using"
    end)

    teardown(function()
        using = nil
    end)

    it("works for functions", function()
        local function foo()
            using.using(math, string)
            assert.equal(math_sin, sin)
            assert.equal(string_sub, sub)
        end

        local function bar()
            foo()
            assert.equal(nil, sin)
            assert.equal(nil, sub)
        end

        bar()
        bar()


        local function baz(t, e)
            using.using(t)
            assert.equal(e.x, x)
            assert.equal(e.y, y)
        end

        local function baz2(t, e)
            baz(t, e)
            assert.equal(nil, x)
            assert.equal(nil, y)
        end

        local t1 = { x = 3, y = -2 }
        local t2 = { x = 42, y = 69 }
        baz(t1, t1)
        baz(t2, t2)
    end)

    it("works for tables", function()
        local pos       = { x = 1, y = 2, z = -3 }
        local entity    = { type = "zombie" }
        using.tusing(entity, pos)

        assert.equal(1, entity.x)
        assert.equal(2, entity.y)
        assert.equal(-3, entity.z)
    end)

    it("errors on non-table arguments", function()
        assert.has_error(function()
            using.using(42)
        end, "expected table, got number (42) (1)")
    end)

    it("errors on duplicate keys", function()
        assert.has_error(function()
            using.using({ x = 1 }, { x = 2 })
        end, "duplicate key 'x'")
    end)
end)