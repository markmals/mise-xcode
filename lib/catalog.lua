--- Installable Xcode releases from the xcodereleases.com catalogue: Apple's signed .xip archives
--- that publish a checksum, one per version for the architecture asked for.

---@class Release
---@field version string 16.4 as published; prereleases add -beta.N, -rc.N, -dp.N, -gm.N, -gm-seed.N
---@field url string An https://download.developer.apple.com/ .xip
---@field sha1? string Lowercase hex; every release has `sha1`, `sha256` or both
---@field sha256? string Lowercase hex
---@field build string Apple's build number, such as `17C52`
---@field created_at string RFC 3339 at midnight UTC; the catalogue records only the day
---@field requires string The oldest macOS that runs this Xcode, such as `15.6`

---@class catalog
local M = {}

local catalogue_url = "https://xcodereleases.com/data.json"

-- The path allows only URL-unreserved characters, `/` and percent escapes.
local trusted_download = "^https://download%.developer%.apple%.com/[%w%-%._~/%%]+$"

-- `RUNTIME.archType` to the name the catalogue's `architectures` lists use.
local catalogue_architectures = { arm64 = "arm64", amd64 = "x86_64" }

local digest_lengths = { sha1 = 40, sha256 = 64 }

-- `version.release` keys whose value is a prerelease number, and the label it takes in a version.
local prerelease_labels = { beta = "beta", rc = "rc", dp = "dp", gm = "gm", gmSeed = "gm-seed" }

--- @param arch string `RUNTIME.archType`
--- @return string
local function catalogue_architecture(arch)
    local name = catalogue_architectures[arch]
    if not name then
        error("Xcode runs on arm64 and amd64 Macs, not " .. tostring(arch))
    end
    return name
end

--- Mise's json module decodes `null` to a userdata sentinel, which counts as absent here.
--- @param value any
--- @return boolean
local function missing(value)
    return value == nil or type(value) == "userdata"
end

--- @param value any
--- @return boolean
local function is_count(value)
    return type(value) == "number" and value >= 1 and value == math.floor(value)
end

--- True for dot-separated decimal numbers such as `26`, `16.4` or `10.15.4`.
--- @param value any
--- @return boolean
local function is_dotted(value)
    return type(value) == "string"
        and value:find("^%d[%d%.]*$") ~= nil
        and value:find("..", 1, true) == nil
        and value:sub(-1) ~= "."
end

--- @param index integer
--- @param problem string
local function reject(index, problem)
    error(("xcodereleases.com catalogue entry %d %s"):format(index, problem))
end

--- Returns `entries` when it is a non-empty array, as the catalogue's top level must be.
--- @param entries any
--- @return table
local function check_envelope(entries)
    local count = 0
    if type(entries) == "table" then
        for _ in pairs(entries) do
            count = count + 1
        end
    end
    if count == 0 or count ~= #entries then
        error("the xcodereleases.com catalogue is not a non-empty JSON array of releases")
    end
    return entries
end

--- Returns the record's download, or nil when it has none.
--- @param index integer
--- @param entry table
--- @return table|nil
local function download_of(index, entry)
    local links = entry.links
    if missing(links) then
        return nil
    end
    if type(links) ~= "table" then
        reject(index, "has malformed links")
    end
    local download = links.download
    if missing(download) then
        return nil
    end
    if type(download) ~= "table" or type(download.url) ~= "string" then
        reject(index, "has a download without a URL")
    end
    return download
end

--- Returns the canonical version and the build number. Upstream numbers are kept as published,
--- never padded: `16.4` stays `16.4`.
--- @param index integer
--- @param version any
--- @return string canonical
--- @return string build
local function read_version(index, version)
    if type(version) ~= "table" or not is_dotted(version.number) then
        reject(index, "has no valid version number")
    end
    if type(version.build) ~= "string" or not version.build:find("^%w+$") then
        reject(index, "has no valid build number")
    end
    local release = version.release
    local kind, value = nil, nil
    if type(release) == "table" then
        kind, value = next(release)
    end
    if kind == nil or next(release, kind) ~= nil then
        reject(index, "needs exactly one release type")
    end
    -- `gm = true` marks the shipped build of Xcode 10 to 12.1, which the catalogue never also lists
    -- as `release = true`.
    if (kind == "release" or kind == "gm") and value == true then
        return version.number, version.build
    end
    local label = prerelease_labels[kind]
    if not label or not is_count(value) then
        reject(index, ("has unknown release type %s = %s"):format(tostring(kind), tostring(value)))
    end
    return ("%s-%s.%d"):format(version.number, label, value), version.build
end

--- @param index integer
--- @param date any
--- @return string
local function created_at(index, date)
    local valid = type(date) == "table"
        and is_count(date.year)
        and date.year <= 9999
        and is_count(date.month)
        and date.month <= 12
        and is_count(date.day)
        and date.day <= 31
    if not valid then
        reject(index, "has no valid date")
    end
    return ("%04d-%02d-%02dT00:00:00Z"):format(date.year, date.month, date.day)
end

--- Returns the published digests keyed by algorithm, or nil when none is published.
--- @param index integer
--- @param checksums any
--- @return table<string, string>|nil
local function digests_of(index, checksums)
    if missing(checksums) then
        return nil
    end
    if type(checksums) ~= "table" then
        reject(index, "has malformed checksums")
    end
    local found = {}
    for algorithm, length in pairs(digest_lengths) do
        local digest = checksums[algorithm]
        if not missing(digest) then
            if type(digest) ~= "string" or #digest ~= length or digest:find("%X") then
                reject(index, "has a malformed " .. algorithm .. " checksum")
            end
            found[algorithm] = digest:lower()
        end
    end
    if next(found) == nil then
        return nil
    end
    return found
end

--- Returns the architectures the download names, or nil for an archive the catalogue never
--- annotated.
--- @param index integer
--- @param download table
--- @return string[]|nil
local function architectures_of(index, download)
    local list = download.architectures
    if missing(list) then
        return nil
    end
    if type(list) ~= "table" or #list == 0 then
        reject(index, "has malformed download architectures")
    end
    for _, name in ipairs(list) do
        if type(name) ~= "string" then
            reject(index, "has malformed download architectures")
        end
    end
    return list
end

--- Ranks a download for `arch`, lower first: built for `arch` alone, built for it among others,
--- then unannotated. Nil when the download does not run on `arch`.
--- @param list string[]|nil
--- @param arch string a catalogue architecture name
--- @return integer|nil
local function preference(list, arch)
    if list == nil then
        return 3
    end
    for _, name in ipairs(list) do
        if name == arch then
            return #list == 1 and 1 or 2
        end
    end
    return nil
end

--- Returns the record as a release with its architectures, or nil when it offers nothing to
--- install: no download, a legacy .dmg or .bin, or no published checksum.
--- @param index integer
--- @param entry any
--- @return Release|nil
--- @return string[]|nil architectures
local function installable(index, entry)
    if type(entry) ~= "table" then
        reject(index, "is not an object")
    end
    local download = download_of(index, entry)
    if not download or not download.url:find("%.xip$") then
        return nil
    end
    if not download.url:find(trusted_download) then
        reject(index, ("downloads from an untrusted URL %q"):format(download.url))
    end
    local version, build = read_version(index, entry.version)
    local date = created_at(index, entry.date)
    if not is_dotted(entry.requires) then
        reject(index, "has no valid minimum macOS version")
    end
    local digests = digests_of(index, entry.checksums)
    local architectures = architectures_of(index, download)
    if not digests then
        return nil
    end
    local release = {
        version = version,
        url = download.url,
        sha1 = digests.sha1,
        sha256 = digests.sha256,
        build = build,
        created_at = date,
        requires = entry.requires,
    }
    return release, architectures
end

--- Returns the installable releases for `arch` (`RUNTIME.archType`) in catalogue order, which is
--- newest first. Each version appears once, at its first position: the download built for `arch`
--- alone wins, and ties keep the catalogue's first record. Raises on a record that breaks the
--- catalogue's schema; skips records without a download, legacy archives and undigested archives.
--- @param entries any the decoded catalogue
--- @param arch string
--- @return Release[]
function M.parse(entries, arch)
    local wanted = catalogue_architecture(arch)
    local releases, slots, ranks = {}, {}, {}
    for index, entry in ipairs(check_envelope(entries)) do
        local release, architectures = installable(index, entry)
        local rank = release and preference(architectures, wanted)
        if release and rank then
            local slot = slots[release.version]
            if not slot then
                table.insert(releases, release)
                slots[release.version] = #releases
                ranks[#releases] = rank
            elseif rank < ranks[slot] then
                releases[slot] = release
                ranks[slot] = rank
            end
        end
    end
    return releases
end

--- Downloads the catalogue anonymously and parses it for `arch` (`RUNTIME.archType`).
--- @param arch string
--- @return Release[]
function M.fetch(arch)
    catalogue_architecture(arch)
    local http = require("http")
    local json = require("json")

    -- No headers: the Apple session cookie belongs to Apple's download host only.
    local response = http.get({ url = catalogue_url })
    if response.status_code ~= 200 then
        error(("fetching %s failed: HTTP %d"):format(catalogue_url, response.status_code))
    end
    local ok, entries = pcall(json.decode, response.body)
    if not ok then
        error(catalogue_url .. " is not valid JSON: " .. tostring(entries))
    end
    return M.parse(entries, arch)
end

--- Returns the release whose canonical version is exactly `version`.
--- @param releases Release[]
--- @param version string
--- @return Release
function M.select(releases, version)
    for _, release in ipairs(releases) do
        if release.version == version then
            return release
        end
    end
    local hint = "versions use the catalogue's numbering, such as 16.4 or 26.1-beta.2"
    error(("Xcode %s is not installable on this architecture; %s"):format(tostring(version), hint))
end

return M
