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
    end)

    --[[
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
    ]]
end)