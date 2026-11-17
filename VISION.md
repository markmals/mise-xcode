---
title: A Vision for mise-xcode
updated: 2026-11-17
---

# A Vision for mise-xcode

## Introduction

mise-xcode lets Apple-platform developers declare Xcode alongside their other Mise tools. A project's Xcode selection travels with its configuration, while downloading and version management use Mise's own engine and Lua plugin hooks.

## Goals

- Make Xcode selection reproducible across developers and CI through native Mise configuration and locking.
- Keep version discovery, architecture selection and installation policy inside a small Lua plugin.
- Preserve the developer's system-wide Xcode selection and existing applications.
- Verify Apple's distributions without redistributing them or depending on another Xcode manager.

## Minimum viable product

A developer can list compatible signed Xcode distributions, pin a stable or prerelease version, install it through Mise, and run Apple tools with that project's Xcode selected. Existing applications can be selected through Mise's native linking command. Apple authentication is supplied through a download-session cookie; license review and first-launch setup remain explicit human actions.

## Design principles

- Mise owns tool lifecycle. Hooks describe downloads and the selected environment rather than introducing a second package manager.
- Selection is project-scoped. `DEVELOPER_DIR` replaces machine-wide `xcode-select` mutations.
- Apple owns distribution trust. Published checksums detect corruption, and Apple's archive and application signatures establish identity.
- Credentials are transient. No Apple passwords, cookies or session values enter project configuration or lockfiles.

## Beyond the minimum

Mise may add Lua APIs that allow an Apple authentication flow without external runtimes. Such support would need separate review of account security and interaction with parallel installs.

## Non-goals

- Managing simulator runtimes or signing identities: these have lifecycles distinct from the Xcode application.
- Accepting licenses or elevating privileges automatically: those actions require the developer's explicit review.
- Installing historical disk-image distributions: signed XIP archives provide a bounded, verifiable installation path.
- Wrapping another Xcode manager: native Mise syntax and lifecycle are the purpose of this plugin.

## Revision history

| Date       | Change                                                                    | Related proposal |
| ---------- | ------------------------------------------------------------------------- | ---------------- |
| 2026-11-17 | Established native Mise Xcode management from the user's project request. | N/A              |
