# mise-xcode

This project follows the Workbench process. Workbench loads from `.workbench`, a gitignored link that `mise install` restores: when `.workbench` is missing or dangling, the harness loads no Workbench content and tasks that call `workbench` fail, so run `mise install`.

This file holds only what is true of this project. The process itself comes from the Workbench package.

## Purpose and layout

A [Mise tool plugin](https://mise.jdx.dev/tool-plugin-development.html) written in Lua 5.1 for Xcode on macOS arm64 and x64.

- `metadata.lua`: plugin metadata, version and `.xcode-version` declaration. Knope owns the version.
- `hooks/`: Mise's discovery, download, installation, environment and version-file entry points.
- `lib/catalog.lua`: public Xcode Releases catalogue, canonical version names, checksums and target architecture variants.
- `lib/xcode.lua`: macOS platform checks, signed XIP expansion and installed application validation.
- `types/`: LuaLS types for Mise's globals and modules.
- `tests/`: deterministic Lua tests; `mise-tasks/test`: isolated native Mise smoke checks.

## Commands

- `mise run test` (`t`): deterministic Lua tests, public-catalogue discovery, missing-credential rejection, and on macOS linking/exercising an existing Xcode in temporary Mise state. No Xcode download, sudo or system-wide selection changes.
- `MISE_DEBUG=1 mise run test`: the same with Mise's debug output, for a failing hook.

## Platform rules and preview

- Mise runs hooks on its embedded Lua 5.1: no `goto`, integer division or `utf8`. lua-language-server checks against 5.1 (`.luarc.json`), and StyLua parses Lua 5.1 (`stylua.toml`).
- Hook files keep their top level to `local` function definitions and the hook; Mise runs every hook file whenever it loads the plugin.
- Build URLs from `RUNTIME`, never from the host: `mise lock` calls `PreInstall` once per locked platform with `RUNTIME` describing that platform.
- Require a published digest for every URL. Xcode Releases primarily publishes SHA-1; `/usr/bin/xip` verifies the archive signature and `/usr/bin/codesign` verifies Apple's application identity.
- Do not wrap `http` calls in `pcall`; it fails in Mise. Use `http.try_get` when a request may fail.
- Never log `MISE_XCODE_COOKIE`, send it to the catalogue, or put it in configuration or a lockfile. `PreInstall.headers` carries it only to the Apple download origin. Require it for installs and locks: Mise 2026.11.9 downloads an artifact to compute its lock SHA-256 instead of recording the published checksum.
- When a hook needs another Mise module, add `types/<module>.lua` with `---@meta <module>` and a `---@class mise.<module>` table, as `types/http.lua` does, so lua-language-server checks its calls and catches misspelled functions.
- Never install, link or test the plugin against your own Mise state. To try a change by hand, run `mise run test`; to review an unreleased plugin in a real project, follow the isolated setup in `mise-tasks/test` rather than `mise plugins link` into your global Mise.
