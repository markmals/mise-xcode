local M = {}

function M.cookie(cookie)
    if
        type(cookie) ~= "string"
        or not cookie:find("%S")
        or not cookie:find("=", 1, true)
        or cookie:find("%c")
    then
        error(
            "set MISE_XCODE_COOKIE to an authenticated Apple Developer download Cookie header; see README.md#apple-authentication"
        )
    end
    return cookie
end

function M.validate(status, content_type)
    local mime = type(content_type) == "string" and content_type:lower():match("^%s*([^;]+)") or ""
    mime = mime:gsub("%s+$", "")
    if
        status ~= 200
        or (
            mime ~= "application/octet-stream"
            and mime ~= "application/x-xip"
            and mime ~= "application/x-xar"
        )
    then
        error(
            "Apple download did not return an XIP archive (HTTP "
                .. status
                .. "); refresh MISE_XCODE_COOKIE and accept pending Apple Developer agreements"
        )
    end
end

function M.headers(url, cookie)
    local http = require("http")
    local headers = { Cookie = M.cookie(cookie) }
    local response = http.head({ url = url, headers = headers })
    M.validate(response.status_code, response.headers["content-type"])
    return headers
end

return M
