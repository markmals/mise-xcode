# mise-xcode

A [Mise](https://mise.jdx.dev/tool-plugin-development.html) Lua plugin for Xcode. Declare the version in `mise.toml`; Mise resolves, downloads, verifies, installs, selects and removes it through its native tool engine.

```toml
[plugins]
xcode = "https://github.com/markmals/mise-xcode"

[tools]
xcode = "16.4"
```

Pin the plugin URL to a reviewed full commit SHA or a published release tag using `#ref`. An unpinned URL follows the default branch. Xcode itself is pinned separately by `[tools]` and `mise.lock`.

## Requirements

- macOS on Apple Silicon or Intel, and Mise 2026.11.9 or later.
- Enough space for the download and expanded Xcode together. Xcode archives are several gigabytes.
- An Apple Developer download-session cookie for installing and locking. Listing versions needs no Apple credentials.
- A macOS version that the selected Xcode supports.

The runtime is Lua inside Mise. It uses Mise's `http`, `json`, `file` and `cmd` modules. The only child programs are macOS's `/usr/bin/xip`, `/usr/bin/codesign` and `/usr/bin/plutil` for signed archive expansion and application verification. There is no `xcodes`, `xcode-install`, Homebrew, Ruby, Python, curl or aria2 dependency.

## Use

```sh
mise ls-remote --prerelease xcode
mise install xcode@16.4
mise use xcode@16.4
mise exec -- xcodebuild -version
mise exec -- xcrun --find swift
mise lock --platform macos-arm64,macos-x64
```

`mise use` writes the project selection. With `mise activate` in your shell, changing projects changes Xcode automatically. `mise exec` uses the selection without shell activation. The plugin sets `DEVELOPER_DIR`, `XCODE_HOME`, `XCODE_VERSION` and Xcode's command/toolchain directories on `PATH`; it never runs `xcode-select` or changes `/Applications`.

Installed applications live at `$(mise where xcode)/Xcode.app`. Open that application once to review Apple's license and complete first-launch setup. The plugin never accepts a license or runs sudo on your behalf. Until setup is complete, Apple tools may report a license or first-launch error.

`mise uninstall xcode@16.4` removes the Mise-managed installation. A version linked with `mise link` remains outside Mise's ownership.

### Apple authentication

Sign in at [Apple Developer Downloads](https://developer.apple.com/download/all/) in your browser and accept any pending developer agreements. Obtain the `Cookie` request-header value for an Xcode download from that authenticated session (including `ADCDownloadAuth` when present). Supply it as `MISE_XCODE_COOKIE` through your environment or a secret manager, then run `mise install`.

The value is a complete Cookie header, such as `ADCDownloadAuth=…`, not an Apple ID or password. Treat it as a credential. Never put it in `mise.toml`, `.xcode-version`, a task command, or a lockfile. Mise sends the header only to the Apple download origin, drops it across origins and keeps it out of lockfiles and header debug output. The plugin sends no credentials to the public catalogue.

The plugin does not implement Apple ID login or two-factor prompts: Mise's Lua HTTP module exposes GET/HEAD/download, not Apple's sign-in POST flow. Refresh an expired session in your browser. A 401/403 or a checksum mismatch caused by an Apple login page requires checking the session and developer agreements.

### Locking

Mise 2026.11.9 computes a Lua tool plugin's lockfile SHA-256 by downloading the entire artifact, even when `PreInstall` supplies a published checksum. `mise lock` therefore requires the Apple session and can download several gigabytes per architecture. The plugin rejects a missing cookie before any Apple download so Mise cannot lock an unauthenticated login page.

Ordinary installation verifies the catalogue checksum. `mise install --locked` additionally enforces Mise's recorded SHA-256; without `--locked`, the published digest still applies. Mise resolves the download URL through `PreInstall` again on installation, then verifies the signed archive and application. Lockfiles contain URLs and digests, never session headers.

### Versions and architectures

Versions come from [Xcode Releases](https://xcodereleases.com/data.json), also used by [Xcodes](https://github.com/XcodesOrg/xcodes). Stable versions retain the catalogue's number (`16.4`). Prereleases use `16.4-beta.1`, `16.4-rc.1`, `8.0-dp.1`, `8.0-gm.1` or `8.0-gm-seed.1`. Ask `mise ls-remote --prerelease xcode` for the exact available names; Mise hides prereleases by default.

Only signed `.xip` distributions are installable. Historical `.dmg` and `.bin` releases are excluded. Apple Silicon chooses an Apple-Silicon-only archive where one exists; Intel chooses a compatible universal archive. The lock hook uses the target platform supplied by Mise, not the host.

The catalogue primarily publishes SHA-1. Mise verifies that checksum (or SHA-256 when published); `/usr/bin/xip` verifies the archive signature, then `codesign` verifies the expanded application's Apple signature and `com.apple.dt.Xcode` identity. SHA-1 alone is not the authenticity guarantee. Release dates are returned to Mise for `minimum_release_age` and `--before`.

### Existing Xcode and version files

Use Mise's own link command to select an existing application without copying it or downloading another archive:

```sh
mise link xcode@16.4 /Applications/Xcode-16.4.app
mise use xcode@16.4
```

Use the application's actual version in the link name. The plugin accepts both a linked `.app` root and its normal managed `Xcode.app` layout. Removing the link with Mise does not delete the external application.

To use an existing `.xcode-version`, enable idiomatic files:

```toml
[settings]
idiomatic_version_file_enable_tools = ["xcode"]
```

The file contains one canonical Mise version, for example `16.4` or `16.4-beta.1`. A project's `[tools]` selection takes precedence. See [Managing Xcode](guides/managing-xcode.md) for the complete workflow.

## Hook contract

| Hook              | Result                                                                                                                      |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `Available`       | Compatible `.xip` versions and release dates, newest first, without Apple authentication.                                   |
| `PreInstall`      | Apple HTTPS URL, published checksum and transient Cookie header. No installation side effects.                              |
| `PostInstall`     | Signed XIP expansion, Apple code-signature and product-version verification, canonical `Xcode.app` layout, archive removal. |
| `EnvKeys`         | Project-scoped Xcode paths and environment, with no commands or machine-wide mutations.                                     |
| `ParseLegacyFile` | One canonical version from `.xcode-version`.                                                                                |

## Development

```sh
mise trust && mise install
mise run setup
mise run check
```

`mise run test` runs deterministic Lua boundary tests and isolated Mise smoke checks against the public catalogue. On macOS it also links an existing Xcode and exercises `xcodebuild`, environment selection, version files and unlinking. It never downloads Xcode or touches your Mise state. CI's macOS runners provide Xcode. The smoke checks do not prove authenticated multi-gigabyte downloads or successful signed XIP expansion.

`mise run fmt` formats Lua with StyLua and Markdown, JSON, TOML and YAML with dprint. `mise run check` additionally runs LuaLS, the other hk linters and Workbench validation. `mise run status` reports workflow and Beads state.

`hooks/` contains the Mise entry points; `lib/catalog.lua` owns catalogue normalization and architecture selection; `lib/xcode.lua` owns macOS installation boundaries; `types/` describes Mise's embedded Lua APIs.

## Releases

Knope versions `metadata.lua` and tags the repository `v<version>`. Every pull request carries a change file created with `workbench change-files create` or a `Release-Note: none` commit trailer. Release workflows run the same blocking gate before publishing a tag. No Xcode binaries are redistributed.
