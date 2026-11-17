function PLUGIN:PostInstall(ctx)
    local xcode = require("xcode")
    xcode.supported(RUNTIME.osType, RUNTIME.archType)
    xcode.install(ctx.rootPath, ctx.runtimeVersion)
end
