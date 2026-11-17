function PLUGIN:EnvKeys(ctx)
    local file = require("file")
    local xcode = require("xcode")
    local app = xcode.app_path(ctx.path)
    local developer = file.join_path(app, "Contents", "Developer")
    return {
        { key = "DEVELOPER_DIR", value = developer },
        { key = "XCODE_HOME", value = app },
        { key = "XCODE_VERSION", value = ctx.version },
        { key = "PATH", value = file.join_path(developer, "usr", "bin") },
        {
            key = "PATH",
            value = file.join_path(
                developer,
                "Toolchains",
                "XcodeDefault.xctoolchain",
                "usr",
                "bin"
            ),
        },
    }
end
