function PLUGIN:Available()
    local xcode = require("xcode")
    local catalog = require("catalog")
    xcode.supported(RUNTIME.osType, RUNTIME.archType)
    local versions = {}
    for _, release in ipairs(catalog.fetch(RUNTIME.archType)) do
        table.insert(versions, { version = release.version, created_at = release.created_at })
    end
    return versions
end
