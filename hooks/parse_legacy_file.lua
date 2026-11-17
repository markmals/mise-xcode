function PLUGIN:ParseLegacyFile(ctx)
    local file = require("file")
    local version = file.read(ctx.filepath):match("^%s*(.-)%s*$")
    if version == "" or version:find("%s") then
        error(".xcode-version must contain one Mise version, for example 16.4 or 16.4-beta.1")
    end
    return { version = version }
end
