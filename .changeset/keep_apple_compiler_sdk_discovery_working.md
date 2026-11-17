---
default: patch
---

# Keep Apple compiler SDK discovery working

Select Xcode through DEVELOPER_DIR while leaving cc, clang and Swift on Apple’s SDK-aware system dispatchers. C and Rust native dependencies can find SDK headers without requiring SDKROOT workarounds.
