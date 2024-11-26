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

    it("works", function()
        local function foo()
            using(math, string)
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
            using(t)
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

    it("errors on non-table arguments", function()
        assert.has_error(function()
            using(42)
        end, "expected table, got number (42) (1)")
    end)

    it("errors on duplicate keys", function()
        assert.has_error(function()
            using({ x = 1 }, { x = 2 })
        end, "duplicate key 'x'")
    end)
end)