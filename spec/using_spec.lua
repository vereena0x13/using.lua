local function asserteq(a, b)
    if a ~= b then
        assert(false, tostring(a) .. " != " .. tostring(b))
    end
end

describe("using.lua", function()
    local using

    setup(function()
        using = require("using")({
            set_global = false
        })
    end)

    teardown(function()
        using = nil
    end)

    describe("using", function()
        it("works", function()
            local function foo()
                using(math, string)
                asserteq(sin, math.sin)
                asserteq(sub, string.sub)
            end

            foo()
            asserteq(sin, nil)
            asserteq(sub, nil)
        end)
    end)
end)