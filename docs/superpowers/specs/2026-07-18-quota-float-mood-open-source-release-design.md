# Quota Float Mood Open-Source Release Design

**Date:** 2026-07-18

**Status:** Approved in conversation; awaiting written-spec confirmation

**Owner:** Mark-0513

## Goal

Publish the existing macOS widget work as a free, open-source GitHub release that ordinary Mac users can download and install without using the Mac App Store. Preserve the upstream project's MIT attribution, invite GitHub Stars without gating functionality, and include Mark's WeChat payment QR code as an entirely optional support channel.

## Repository Model

Use a public GitHub fork rather than an unrelated repository or an upstream-only pull request:

- Repository: `Mark-0513/quota-float-mood`
- Product name: `Quota Float Mood`
- Upstream: `change-42-yhmm/quota-float`
- License: MIT, retaining the existing license and copyright notice
- Initial enhanced release: `v0.2.0`

The fork remains independently downloadable and maintainable even if upstream does not accept the widget work. Reusable changes can later be proposed upstream as several focused pull requests.

## Attribution Boundary

The README must distinguish the upstream project from Mark's enhancement:

- State that Quota Float Mood is based on `change-42-yhmm/quota-float` under the MIT License.
- Credit the upstream Quota Float contributors for the original desktop quota application.
- Credit `Mark-0513` for the macOS WidgetKit integration, emotional quota states, and six visual themes.
- Label the payment QR code as support for the enhanced edition's maintainer, not as a payment to the upstream author.

No original authorship claim will be made for upstream code.

## Product Identity

The enhanced edition must not overwrite or update from the upstream application:

- Display name: `Quota Float Mood`
- Main bundle identifier: `com.mark0513.quotafloatmood`
- Widget bundle identifier: `com.mark0513.quotafloatmood.widget`
- Widget names and Gallery descriptions: use `Quota Float Mood`
- Update and release URLs: point only to `Mark-0513/quota-float-mood`

The six existing widget themes remain:

1. Pixel
2. Terminal
3. Vault
4. Black Gold
5. Sticker
6. Proud Bot

Each theme supports small and medium macOS widget sizes.

## README Information Architecture

Keep the public page short and action-first:

1. Product name and one-sentence description
2. Screenshot showing the six themes
3. A prominent `免费下载最新版` link to GitHub Releases
4. One exact filename for ordinary users
5. Three installation steps
6. Requirements and privacy boundary
7. A short Star request
8. Optional WeChat support section
9. Upstream attribution and MIT license
10. Development and contribution commands

The primary download copy will be:

> 点击“免费下载最新版”，下载 `Quota-Float-Mood-v0.2.0-macOS-Universal.dmg`。支持 Intel 与 Apple 芯片 Mac，需要 macOS 14 或更高版本。

Installation copy will be limited to:

1. Download and open the DMG.
2. Drag Quota Float Mood into Applications.
3. Open the app, then search for Quota Float Mood in the macOS widget gallery.

## Star and Voluntary Support

The README will ask users who find the project useful to click the repository's Star button so more users can discover it. Stars, payment, registration, and telemetry will never unlock or affect functionality.

The supplied 828 x 1124 JPEG will be stored at `docs/images/wechat-support.jpg`. The support copy will say that the software is free and open source, payment is optional, and declining to pay does not affect any feature.

Because the QR code will be committed to a public repository, it should be treated as permanently public and reusable outside GitHub. This is intentional based on the owner's explicit request.

## Release Artifact

The ordinary-user artifact will have one unambiguous name:

`Quota-Float-Mood-v0.2.0-macOS-Universal.dmg`

It will contain a universal macOS application for Apple Silicon and Intel. GitHub's automatic source archives remain available for developers but will not be presented as installation downloads.

The Release notes will include:

- six emotional widget themes in small and medium sizes
- macOS 14 minimum requirement
- requirement for an existing signed-in Codex Desktop installation
- privacy statement
- installation steps
- upstream attribution
- SHA-256 checksum

## Signing and Notarization

The current machine has Apple Development and Apple Distribution identities but no `Developer ID Application` identity. Apple Distribution is for App Store distribution and must not be substituted for Developer ID signing.

Release policy:

1. First attempt to obtain and use a valid `Developer ID Application` identity from Mark's Apple Developer team, enable Hardened Runtime, notarize the DMG/app, staple the notarization ticket, and verify with `spctl`.
2. If the required Developer ID identity or notarization credentials are unavailable, publish `v0.2.0` explicitly as an unsigned public beta rather than pretending it is notarized. The README and Release notes must then include the exact Gatekeeper approval steps.
3. Replace the beta with a signed and notarized release once the credentials are available; never commit certificates, private keys, passwords, or signing secrets.

The release must not claim smooth Gatekeeper installation unless `spctl` verifies the downloaded artifact successfully.

## Automation and Secrets

GitHub Actions will run frontend, Rust, and WidgetKit tests and create the universal macOS artifact. Signing and notarization secrets, if configured, will be stored only as GitHub Actions secrets. Workflows triggered from untrusted pull requests must not receive those secrets.

The updater endpoint and Tauri signing key must belong to Mark's fork. Until a fork-owned updater signing key is configured, automatic updates must be disabled rather than continuing to trust the upstream release channel.

## Upstream Contribution Strategy

Public distribution does not wait for upstream acceptance. After the fork release is stable, propose focused upstream pull requests in this order:

1. quota snapshot cache and data boundary
2. macOS WidgetKit extension and build integration
3. base widget and accessibility behavior
4. optional theme set

Each pull request will preserve upstream privacy rules and include relevant tests. The six-theme feature will not be submitted as a single unreviewable mega-PR.

## Verification

Before publishing the final download link:

- run all frontend, Rust, and WidgetKit tests
- build a clean universal Release artifact
- confirm both `arm64` and `x86_64` slices
- verify main app and nested widget signatures
- verify notarization/Gatekeeper status, or label the release unsigned
- install from the exact DMG intended for GitHub
- confirm all 12 widget gallery entries appear
- confirm live quota retrieval and unavailable-state behavior
- scan the repository and artifact for credentials and local paths
- download the published asset from GitHub and verify its SHA-256 checksum
- verify README download, upstream, Star, and support-image links while logged out

## Success Criteria

The work is complete when a logged-out visitor can open `Mark-0513/quota-float-mood`, understand the upstream relationship, download one clearly named macOS artifact, follow the short installation instructions, see the optional Star and support requests, and successfully add any of the six themes in small or medium size.
