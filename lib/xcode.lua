local M = {}

function M.supported(os_type, arch)
    if os_type ~= "darwin" or (arch ~= "arm64" and arch ~= "amd64") then
        error("xcode supports macOS on arm64 and x64, not " .. os_type .. "-" .. arch)
    end
end

function M.quote(argument)
    return "'" .. argument:gsub("'", "'\\''") .. "'"
end

local function normalized(number)
    return (number:gsub("%.0$", ""):gsub("%.0$", ""))
end

function M.match_version(installed, requested)
    local number, suffix = requested:match("^([%d.]+)(.*)$")
    local valid_number = number and (number:match("^%d+%.%d+$") or number:match("^%d+%.%d+%.%d+$"))
    local valid_suffix = suffix == ""
    for _, kind in ipairs({ "beta", "rc", "dp", "gm", "gm%-seed" }) do
        valid_suffix = valid_suffix or (suffix and suffix:match("^%-" .. kind .. "%.%d+$"))
    end
    if not valid_number or not valid_suffix then
        error("invalid Xcode version: " .. requested)
    end
    if normalized(installed) ~= normalized(number) then
        error("expected Xcode " .. requested .. ", but the application reports " .. installed)
    end
end

function M.app_path(root)
    local file = require("file")
    for _, app in ipairs({ file.join_path(root, "Xcode.app"), root }) do
        if
            file.exists(file.join_path(app, "Contents", "Developer", "usr", "bin", "xcodebuild"))
        then
            return app
        end
    end
    error("no Xcode application at " .. root .. "; reinstall it or update the mise link")
end

local function application_in(root)
    local file = require("file")
    local apps = {}
    for _, path in ipairs(file.list(root)) do
        if path:match("%.app$") and file.stat(path).is_dir then
            table.insert(apps, path)
        end
    end
    if #apps ~= 1 then
        error("expected one Xcode application after expanding the archive, found " .. #apps)
    end
    return apps[1]
end

function M.install(root, version)
    local file = require("file")
    local cmd = require("cmd")
    local archives = {}
    for _, path in ipairs(file.list(root)) do
        if path:match("%.xip$") and file.stat(path).is_file then
            table.insert(archives, path)
        end
    end
    if #archives ~= 1 then
        error(
            "expected one signed .xip archive, found "
                .. #archives
                .. "; check the Apple download session"
        )
    end

    print("Expanding Apple's signed XIP archive; this can take several minutes")
    cmd.exec("/usr/bin/xip --expand " .. M.quote(archives[1]), { cwd = root })
    local app = application_in(root)
    print("Verifying Xcode's Apple signature")
    cmd.exec(
        "/usr/bin/codesign --verify --deep --strict -R "
            .. M.quote('=anchor apple and identifier "com.apple.dt.Xcode"')
            .. " "
            .. M.quote(app)
    )
    local installed = cmd.exec(
        "/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "
            .. M.quote(file.join_path(app, "Contents", "Info.plist"))
    )
    M.match_version(installed:gsub("%s+$", ""), version)
    M.app_path(app)
    local destination = file.join_path(root, "Xcode.app")
    if app ~= destination then
        file.move(app, destination)
    end
    assert(os.remove(archives[1]))
    print(
        "Xcode installed. Open XCODE_HOME once to review Apple's license and install first-launch components; no system-wide selection was changed."
    )
end

return M
