---
id: guide.managing-xcode
title: Managing Xcode
---

# Managing Xcode

## What it does

A project's Mise tool selection chooses the Xcode used by `xcodebuild`, `xcrun` and Swift commands. The [hook contract and platform requirements](../README.md#hook-contract) define discovery, installation and environment behavior. The plugin leaves your system-wide Xcode selection unchanged.

## How to use it

1. Add the plugin URL and an Xcode version under `[plugins]` and `[tools]` in `mise.toml`, as shown in the [README](../README.md).
2. Set `MISE_XCODE_COOKIE` from an authenticated Apple Developer download request through your environment or secret manager. The [authentication instructions](../README.md#apple-authentication) describe obtaining and protecting it.
3. Run `mise install`. Mise downloads and checks the archive; the plugin expands and verifies Apple's signatures.
4. Open `$(mise where xcode)/Xcode.app` to review the license and complete Apple's setup. Then run `mise exec -- xcodebuild -version` to confirm the selection.

Run `mise ls-remote --prerelease xcode` to find other releases, including names such as `16.4-rc.1`. `mise use xcode@16.4` changes the project pin. Use `mise uninstall xcode@16.4` only when no project still needs that installation.

## Worked example

For an existing `/Applications/Xcode-16.4.app`, run:

```sh
mise link xcode@16.4 /Applications/Xcode-16.4.app
mise use xcode@16.4
mise exec -- xcodebuild -version
```

The command reports Xcode 16.4. `DEVELOPER_DIR` points into that application while the command runs, independent of the machine-wide `xcode-select` setting. `mise uninstall xcode@16.4` removes the Mise link and leaves the application in `/Applications` intact.

C, C++ and Swift commands use Apple's system dispatchers with `DEVELOPER_DIR` pointing at the selected Xcode. The plugin leaves the raw toolchain directory off `PATH` so native builds discover the SDK normally; no global `SDKROOT` setting is needed.

## Limits and edge cases

- `mise lock --platform macos-arm64,macos-x64` needs the Apple session. Mise 2026.11.9 downloads each artifact to compute its lockfile SHA-256; locking can transfer several gigabytes per platform. Keep the cookie out of TOML and lockfiles.
- An expired session, rejected agreements or an Apple login response stops installation. Refresh the browser session rather than turning off verification.
- Intel cannot install Apple-Silicon-only distributions. The catalogue selects a compatible variant per target architecture; historical DMG/BIN installers are excluded.
- To read `.xcode-version`, enable `idiomatic_version_file_enable_tools = ["xcode"]` in `[settings]`. Put exactly one canonical Mise version in the file. A `[tools]` pin wins over the file.
- Xcode versions have macOS requirements, and first-launch setup may need administrator approval. The plugin does not elevate privileges, accept terms, download simulator runtimes or manage signing credentials.
