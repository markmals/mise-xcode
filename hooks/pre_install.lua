function PLUGIN:PreInstall(ctx)
    local xcode = require("xcode")
    local catalog = require("catalog")
    local download = require("download")
    xcode.supported(RUNTIME.osType, RUNTIME.archType)
    local cookie = download.cookie(os.getenv("MISE_XCODE_COOKIE"))
    local release = catalog.select(catalog.fetch(RUNTIME.archType), ctx.version)
    return {
        version = ctx.version,
        url = release.url,
        sha256 = release.sha256,
        sha1 = release.sha1,
        headers = download.headers(release.url, cookie),
    }
end
