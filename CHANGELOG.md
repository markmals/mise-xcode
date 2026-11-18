## 0.1.1 (2026-11-18)

### Features

#### Manage Xcode through native Mise Lua hooks

Declare stable or prerelease Xcode versions in mise.toml, select existing applications with mise link, and use project-scoped Apple toolchains without xcodes or wrapper scripts. Downloads require an Apple Developer session and verify signed XIP archives.

### Fixes

#### Keep Apple compiler SDK discovery working

Select Xcode through DEVELOPER_DIR while leaving cc, clang and Swift on Apple’s SDK-aware system dispatchers. C and Rust native dependencies can find SDK headers without requiring SDKROOT workarounds.
