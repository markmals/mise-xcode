package.path = "lib/?.lua;" .. package.path

local download = require("download")

local function rejects(fragment, action)
    local ok, failure = pcall(action)
    assert(not ok and tostring(failure):find(fragment, 1, true), tostring(failure))
end

assert(
    download.cookie("ADCDownloadAuth=secret; other=token") == "ADCDownloadAuth=secret; other=token"
)
for _, cookie in ipairs({ "", "   ", "secret", "ADCDownloadAuth=secret\r\nOther: injected" }) do
    rejects("MISE_XCODE_COOKIE", function()
        download.cookie(cookie)
    end)
end
rejects("MISE_XCODE_COOKIE", function()
    download.cookie(nil)
end)

download.validate(200, "application/octet-stream")
download.validate(200, "application/x-xip; charset=binary")
for _, status in ipairs({ 302, 401, 403, 500 }) do
    rejects("Apple download", function()
        download.validate(status, "application/octet-stream")
    end)
end
for _, mime in ipairs({ "text/html", "application/xhtml+xml", "application/json", "" }) do
    rejects("Apple download", function()
        download.validate(200, mime)
    end)
end
rejects("Apple download", function()
    download.validate(200, nil)
end)

print("PASS: Apple session and login-page rejection boundaries")
