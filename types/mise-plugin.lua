---@meta
--- lua-language-server types for the globals and hook contexts Mise gives a tool plugin. They follow
--- https://mise.jdx.dev/tool-plugin-development.html and https://mise.jdx.dev/plugin-lua-modules.html.
--- Mise runs hooks on Lua 5.1. The modules hooks `require` have their own files in this directory.

---@class Runtime
---@field osType "linux"|"darwin"|"windows"
---@field archType string `amd64`, `arm64`, or another architecture name such as `x86` or `riscv64`
---@field envType? "gnu"|"musl" Linux's libc; nil on other systems and while `mise lock` targets another platform
---@field version string The vfox API version Mise implements, not the Mise version
---@field pluginDirPath string The plugin's installed directory
---@field cacheDirPath? string A cache directory that outlives plugin reinstalls; `mise cache clear` empties it

--- The platform a hook targets. While `mise lock` records another platform, it describes that one.
---@type Runtime
RUNTIME = {}

---@class Plugin
---@field name string
---@field version string
---@field description? string
---@field homepage? string
---@field license? string
---@field legacyFilenames? string[] Version files that ParseLegacyFile reads
---@field depends? string[] Tools Mise installs first and puts on PATH for the install hooks
---@field downloads? boolean `false` when PreInstall never returns a URL
---@field Available fun(self: Plugin, ctx: AvailableCtx): AvailableVersion[]
---@field PreInstall fun(self: Plugin, ctx: PreInstallCtx): PreInstallResult
---@field EnvKeys fun(self: Plugin, ctx: EnvKeysCtx): EnvKey[]
---@field PostInstall? fun(self: Plugin, ctx: PostInstallCtx)
---@field MiseInstallSatisfied? fun(self: Plugin, ctx: MiseInstallSatisfiedCtx): boolean|{ satisfied: boolean, reason?: string }|nil
---@field PreUninstall? fun(self: Plugin, ctx: PreUninstallCtx)
---@field ParseLegacyFile? fun(self: Plugin, ctx: ParseLegacyFileCtx): { version?: string }

--- The table metadata.lua defines; every hook is a method on it.
---@type Plugin
PLUGIN = {}

--- A tool's options from mise.toml. Top-level booleans and numbers arrive as strings, so compare
--- `options.flag == "true"`; arrays and tables keep their TOML types.
---@alias ToolOptions table<string, any>

---@class SdkInfo
---@field name string
---@field version string
---@field path string The install directory

---@class AvailableCtx
---@field args string[] Always empty in Mise

---@class AvailableVersion
---@field version string
---@field created_at? string RFC 3339 release time; Mise uses it for `minimum_release_age` and `--before`
---@field rolling? boolean `true` for a channel such as `nightly` whose contents change
---@field checksum? string For a rolling channel, the SHA-256 of the platform's current asset

---@class PreInstallCtx
---@field version string The resolved version to install
---@field options ToolOptions

---@class PreInstallAttestation
---@field github_owner? string
---@field github_repo? string
---@field github_signer_workflow? string
---@field cosign_sig_or_bundle_path? string
---@field cosign_public_key_path? string
---@field cosign_certificate_identity? string
---@field cosign_certificate_identity_regexp? string
---@field cosign_certificate_oidc_issuer? string
---@field slsa_provenance_path? string
---@field slsa_signer_identity? string
---@field slsa_signer_issuer? string
---@field slsa_min_level? integer
---@field slsa_source_repository? string
---@field slsa_source_tag? string

---@class PreInstallResult
---@field version string
---@field url? string The file to download; without one, PostInstall does the install
---@field sha256? string
---@field sha512? string
---@field sha1? string
---@field md5? string
---@field headers? table<string, string> Sent only to the origin of `url`
---@field attestation? PreInstallAttestation

---@class PostInstallCtx
---@field rootPath string The install directory
---@field runtimeVersion string
---@field sdkInfo table<string, SdkInfo> Keyed by `PLUGIN.name`
---@field options ToolOptions

---@class EnvKeysCtx
---@field path string The install directory
---@field version string
---@field main SdkInfo
---@field sdkInfo table<string, SdkInfo> Keyed by `PLUGIN.name`
---@field options ToolOptions

---@class EnvKey
---@field key string
---@field value string One value; return each PATH directory as its own entry

---@class MiseInstallSatisfiedCtx
---@field path string
---@field version string
---@field options ToolOptions

---@class PreUninstallCtx
---@field main SdkInfo
---@field sdkInfo table<string, SdkInfo>

---@class ParseLegacyFileCtx
---@field filename string
---@field filepath string
---@field getInstalledVersions fun(): string[] Calls Available in Mise, despite its name
