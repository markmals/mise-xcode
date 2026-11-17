package.path = "lib/?.lua;" .. package.path

local xcode = require("xcode")

local function rejects(fragment, action)
    local ok, failure = pcall(action)
    assert(not ok and tostring(failure):find(fragment, 1, true), tostring(failure))
end

xcode.supported("darwin", "arm64")
xcode.supported("darwin", "amd64")
rejects("not linux-arm64", function()
    xcode.supported("linux", "arm64")
end)
rejects("not darwin-riscv64", function()
    xcode.supported("darwin", "riscv64")
end)

assert(xcode.quote("/a path/Xcode's.app") == "'/a path/Xcode'\\''s.app'")
assert(xcode.quote("$(touch /tmp/unwanted);'") == "'$(touch /tmp/unwanted);'\\'''")

xcode.match_version("16.4", "16.4")
xcode.match_version("16.4.0", "16.4-beta.2")
xcode.match_version("16.4", "16.4.0")
rejects("expected Xcode 16.4", function()
    xcode.match_version("16.3", "16.4-rc.1")
end)
rejects("invalid Xcode version", function()
    xcode.match_version("16.4", "16.4; echo unsafe")
end)

print("PASS: Xcode platform, shell arguments and installed version boundaries")
