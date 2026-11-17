package.path = "lib/?.lua;" .. package.path

local catalog = require("catalog")

local origin = "https://download.developer.apple.com/Developer_Tools/"
local sha1 = string.rep("a", 40)
local arm64_only = { "arm64" }
local universal = { "arm64", "x86_64" }
-- Mise's json module decodes `null` to userdata, which `newproxy` also makes.
local null = newproxy(false)

local function rejects(fragment, action)
    local ok, failure = pcall(action)
    assert(not ok and tostring(failure):find(fragment, 1, true), tostring(failure))
end

local function expect(actual, expected)
    assert(actual == expected, ("expected %s, got %s"):format(tostring(expected), tostring(actual)))
end

---@return table<string, any>
local function record(spec)
    return {
        name = "Xcode",
        version = {
            number = spec.number,
            build = spec.build or "17A324",
            release = spec.release or { release = true },
        },
        date = spec.date or { year = 2025, month = 9, day = 15 },
        requires = "15.6",
        links = {
            download = {
                url = origin .. (spec.file or "Xcode.xip"),
                architectures = spec.architectures,
            },
        },
        checksums = { sha1 = spec.sha1 or sha1 },
    }
end

local function versions(releases)
    local list = {}
    for _, release in ipairs(releases) do
        table.insert(list, release.version)
    end
    return table.concat(list, " ")
end

-- The URL and digest must come from the same catalogue record.
local function expect_download(release, file, digest)
    expect(release.url, origin .. file)
    expect(release.sha1, digest)
end

-- Parses one 16.4 record after `change` edits it.
local function parse_one(change)
    local entry = record({ number = "16.4" })
    change(entry)
    return catalog.parse({ entry }, "arm64")
end

local function canonical(release, number)
    local entry = record({ number = number or "16.4", release = release })
    return catalog.parse({ entry }, "arm64")[1].version
end

-- Architecture variants collapse to one version, in catalogue order, per architecture.
local digest = {
    beta = string.rep("1", 40),
    silicon_26_1 = string.rep("2", 40),
    universal_26_1 = string.rep("3", 40),
    silicon_26_0 = string.rep("4", 40),
    universal_26_0 = string.rep("5", 40),
    unannotated = string.rep("6", 40),
}
local variants = {
    record({
        number = "27.0",
        release = { beta = 1 },
        file = "Xcode_27_beta.xip",
        architectures = arm64_only,
        sha1 = digest.beta,
    }),
    record({
        number = "26.1",
        file = "Xcode_26.1_Universal.xip",
        architectures = universal,
        sha1 = digest.universal_26_1,
    }),
    record({
        number = "26.1",
        file = "Xcode_26.1_Apple_silicon.xip",
        architectures = arm64_only,
        sha1 = digest.silicon_26_1,
    }),
    record({
        number = "26.0",
        file = "Xcode_26_Apple_silicon.xip",
        architectures = arm64_only,
        sha1 = digest.silicon_26_0,
    }),
    record({
        number = "26.0",
        file = "Xcode_26_Universal.xip",
        architectures = universal,
        sha1 = digest.universal_26_0,
    }),
    record({ number = "16.4", file = "Xcode_16.4.xip", sha1 = digest.unannotated }),
}

local arm64 = catalog.parse(variants, "arm64")
expect(versions(arm64), "27.0-beta.1 26.1 26.0 16.4")
expect_download(arm64[1], "Xcode_27_beta.xip", digest.beta)
expect_download(arm64[2], "Xcode_26.1_Apple_silicon.xip", digest.silicon_26_1)
expect_download(arm64[3], "Xcode_26_Apple_silicon.xip", digest.silicon_26_0)
expect_download(arm64[4], "Xcode_16.4.xip", digest.unannotated)

local amd64 = catalog.parse(variants, "amd64")
expect(versions(amd64), "26.1 26.0 16.4")
expect_download(amd64[1], "Xcode_26.1_Universal.xip", digest.universal_26_1)
expect_download(amd64[2], "Xcode_26_Universal.xip", digest.universal_26_0)
expect_download(amd64[3], "Xcode_16.4.xip", digest.unannotated)

local intel_only = { record({ number = "15.0", architectures = { "x86_64" } }) }
expect(versions(catalog.parse(intel_only, "arm64")), "")
expect(versions(catalog.parse(intel_only, "amd64")), "15.0")

local annotated = catalog.parse({
    record({ number = "26.0", file = "Xcode_26.xip", sha1 = digest.unannotated }),
    record({
        number = "26.0",
        file = "Xcode_26_Universal.xip",
        architectures = universal,
        sha1 = digest.universal_26_0,
    }),
}, "amd64")
expect_download(annotated[1], "Xcode_26_Universal.xip", digest.universal_26_0)

rejects("not x86", function()
    catalog.parse(variants, "x86")
end)
rejects("not riscv64", function()
    catalog.fetch("riscv64")
end)
rejects("malformed download architectures", function()
    parse_one(function(entry)
        entry.links.download.architectures = "arm64"
    end)
end)
rejects("malformed download architectures", function()
    parse_one(function(entry)
        entry.links.download.architectures = {}
    end)
end)
expect(
    versions(parse_one(function(entry)
        entry.links.download.architectures = null
    end)),
    "16.4"
)

-- Distinct builds published under one version keep the catalogue's first, on every architecture.
local first_build, second_build = string.rep("7", 40), string.rep("8", 40)
local rebuilt = {
    record({
        number = "13.0",
        release = { beta = 3 },
        build = "13A5192j",
        file = "Xcode_13_beta3.xip",
        sha1 = first_build,
    }),
    record({
        number = "13.0",
        release = { beta = 3 },
        build = "13A5192i",
        file = "Xcode_13_beta_3.xip",
        sha1 = second_build,
    }),
}
for _, arch in ipairs({ "arm64", "amd64" }) do
    local releases = catalog.parse(rebuilt, arch)
    expect(versions(releases), "13.0-beta.3")
    expect(releases[1].build, "13A5192j")
    expect_download(releases[1], "Xcode_13_beta3.xip", first_build)
end

-- Release types: stable numbers stay unpadded, and `gm = true` is the shipped build.
expect(canonical({ release = true }), "16.4")
expect(canonical({ release = true }, "26.0.1"), "26.0.1")
expect(canonical({ beta = 2 }), "16.4-beta.2")
expect(canonical({ rc = 1 }), "16.4-rc.1")
expect(canonical({ dp = 3 }), "16.4-dp.3")
expect(canonical({ gmSeed = 2 }, "11.0"), "11.0-gm-seed.2")
expect(canonical({ gm = true }, "11.0"), "11.0")
expect(canonical({ gm = 2 }, "11.0"), "11.0-gm.2")
rejects("unknown release type alpha = 1", function()
    canonical({ alpha = 1 })
end)
rejects("unknown release type release = false", function()
    canonical({ release = false })
end)
rejects("unknown release type beta = 0", function()
    canonical({ beta = 0 })
end)
rejects("unknown release type rc = 1.5", function()
    canonical({ rc = 1.5 })
end)
rejects("needs exactly one release type", function()
    canonical({ beta = 1, rc = 1 })
end)
rejects("needs exactly one release type", function()
    parse_one(function(entry)
        entry.version.release = nil
    end)
end)

-- Missing version metadata fails clearly instead of producing an unusable version.
rejects("entry 1 has no valid version number", function()
    parse_one(function(entry)
        entry.version.number = nil
    end)
end)
rejects("has no valid version number", function()
    parse_one(function(entry)
        entry.version.number = "16.4 beta"
    end)
end)
rejects("has no valid build number", function()
    parse_one(function(entry)
        entry.version.build = nil
    end)
end)
rejects("has no valid date", function()
    parse_one(function(entry)
        entry.date = nil
    end)
end)
rejects("has no valid date", function()
    parse_one(function(entry)
        entry.date.month = 13
    end)
end)
rejects("has no valid minimum macOS version", function()
    parse_one(function(entry)
        entry.requires = nil
    end)
end)

-- Release dates and fields; catalogue order wins over date order.
local dated = catalog.parse({
    record({
        number = "26.4",
        release = { beta = 1 },
        date = { year = 2026, month = 2, day = 16 },
    }),
    record({ number = "26.3", build = "17C529", date = { year = 2026, month = 2, day = 26 } }),
}, "arm64")
expect(versions(dated), "26.4-beta.1 26.3")
expect(dated[1].created_at, "2026-02-16T00:00:00Z")
expect(dated[2].created_at, "2026-02-26T00:00:00Z")
expect(dated[2].build, "17C529")
expect(dated[2].requires, "15.6")
expect(dated[2].sha256, nil)

-- Digests: an absent one makes its record uninstallable, a malformed one fails.
local undigested = record({
    number = "26.1",
    file = "Xcode_26.1_Apple_silicon.xip",
    architectures = arm64_only,
})
undigested.checksums = nil
local fallback = catalog.parse({
    undigested,
    record({
        number = "26.1",
        file = "Xcode_26.1_Universal.xip",
        architectures = universal,
        sha1 = digest.universal_26_1,
    }),
}, "arm64")
expect(versions(fallback), "26.1")
expect_download(fallback[1], "Xcode_26.1_Universal.xip", digest.universal_26_1)

for _, checksums in ipairs({ null, {}, { sha1 = null }, { md5 = string.rep("a", 32) } }) do
    expect(#parse_one(function(entry)
        entry.checksums = checksums
    end), 0)
end

local both = parse_one(function(entry)
    entry.checksums = { sha1 = string.rep("A", 40), sha256 = string.rep("C", 64) }
end)[1]
expect(both.sha1, string.rep("a", 40))
expect(both.sha256, string.rep("c", 64))

local malformed = {
    { fragment = "malformed sha1 checksum", checksums = { sha1 = string.rep("a", 39) } },
    { fragment = "malformed sha1 checksum", checksums = { sha1 = string.rep("g", 40) } },
    { fragment = "malformed sha1 checksum", checksums = { sha1 = "" } },
    { fragment = "malformed sha256 checksum", checksums = { sha1 = sha1, sha256 = sha1 } },
    { fragment = "malformed checksums", checksums = sha1 },
}
for _, case in ipairs(malformed) do
    rejects(case.fragment, function()
        parse_one(function(entry)
            entry.checksums = case.checksums
        end)
    end)
end

-- Only Apple's HTTPS download host may serve an archive.
local untrusted = {
    "http://download.developer.apple.com/Developer_Tools/Xcode.xip",
    "https://download.developer.apple.com.example.net/Xcode.xip",
    "https://download.developer.apple.com@example.net/Xcode.xip",
    "https://download.developer.apple.com:8443/Xcode.xip",
    "https://example.net/download.developer.apple.com/Xcode.xip",
    "https://download.developer.apple.com/Developer Tools/Xcode.xip",
}
for _, url in ipairs(untrusted) do
    rejects("untrusted URL", function()
        parse_one(function(entry)
            entry.links.download.url = url
        end)
    end)
end
rejects("download without a URL", function()
    parse_one(function(entry)
        entry.links.download = {}
    end)
end)

-- Records without a download and legacy archives are skipped before their metadata is read.
local legacy = {
    record({ number = "8.0", release = { alpha = 1 }, file = "Xcode_8.dmg" }),
    record({ number = "3.2", release = { alpha = 1 }, file = "xcode_3.2.bin" }),
    record({ number = "4.5", release = { alpha = 1 } }),
    record({ number = "4.4", release = { alpha = 1 } }),
    record({ number = "4.3", release = { alpha = 1 } }),
    record({ number = "16.4" }),
}
legacy[3].links = nil
legacy[4].links = { notes = { url = "https://developer.apple.com/" } }
legacy[5].links.download = null
expect(versions(catalog.parse(legacy, "arm64")), "16.4")

-- The catalogue envelope.
for _, entries in ipairs({ "[]", {}, { version = {} }, null }) do
    rejects("not a non-empty JSON array", function()
        catalog.parse(entries, "arm64")
    end)
end
rejects("entry 2 is not an object", function()
    catalog.parse({ record({ number = "16.4" }), null }, "arm64")
end)

-- Selection is exact on the canonical version and returns the variant's own URL and digest.
local Xcode_26_1_arm64 = catalog.select(arm64, "26.1")
expect_download(Xcode_26_1_arm64, "Xcode_26.1_Apple_silicon.xip", digest.silicon_26_1)
local Xcode_26_1_amd64 = catalog.select(amd64, "26.1")
expect_download(Xcode_26_1_amd64, "Xcode_26.1_Universal.xip", digest.universal_26_1)
expect(catalog.select(arm64, "27.0-beta.1").version, "27.0-beta.1")
rejects("Xcode 16.4.0 is not installable", function()
    catalog.select(arm64, "16.4.0")
end)
rejects("Xcode 27.0-beta.1 is not installable", function()
    catalog.select(amd64, "27.0-beta.1")
end)

-- The catalogue request carries no headers, so no cookie, and its failures are explained.
local requests, response = {}, { status_code = 200, body = "catalogue" }
package.loaded.http = {
    get = function(request)
        table.insert(requests, request)
        return response
    end,
}
package.loaded.json = {
    decode = function(text)
        if text ~= "catalogue" then
            error("expected value at line 1 column 1")
        end
        return variants
    end,
}
expect(versions(catalog.fetch("amd64")), "26.1 26.0 16.4")
expect(requests[1].url, "https://xcodereleases.com/data.json")
expect(requests[1].headers, nil)
response = { status_code = 503, body = "" }
rejects("https://xcodereleases.com/data.json failed: HTTP 503", function()
    catalog.fetch("arm64")
end)
response = { status_code = 200, body = "<html>" }
rejects("https://xcodereleases.com/data.json is not valid JSON", function()
    catalog.fetch("arm64")
end)

print("PASS: Xcode catalogue architectures, versions, dates, digests, URLs and selection")
