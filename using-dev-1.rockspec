rockspec_format = "3.0"

package = "using"
version = "dev-1"

source = {
    url = "git://github.com/vereena0x13/using.lua.git",
    branch = "main"
}

description = {
    summary = "Casual sin for negative profit and killing time / brain cells.",
    detailed = [[
        Just a toy project to pass the time.
    ]],
    homepage = "https://github.com/vereena0x13/using.lua",
    issues_url = "https://github.com/vereena0x13/using.lua/issues",
    maintainer = "vereena0x13",
    license = "MIT",
    labels = {}
}

dependencies = {
    "lua == 5.1"
}

build = {
    type = "builtin",
    modules = {
        ["using"] = "using.lua"
    },
    copy_directories = {
        "spec"
    }
}

test_dependencies = {
    "busted",
    "busted-htest"
}

test = {
    type = "busted"
}