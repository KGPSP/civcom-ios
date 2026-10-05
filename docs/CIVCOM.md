# CIVCOM iOS

First CIVCOM marketing version: 1.0.0 (build 1). Upstream 26.09.2 is provenance, not the CIVCOM release version.

Publisher: KG PSP. Fork: https://github.com/KGPSP/civcom-ios.
Unmodified provenance: Element X iOS release/26.09.2,
`47f881c5077c5a924abe4805b34097a1a2902a34`.
Preserved upstream history and LICENSE apply; this is not an SDK fork.

## Native identities

| Configuration | APNs topic / application ID | App group | Pusher app_id |
|---|---|---|---|
| Debug | pl.gov.psp.civcom.dev | group.pl.gov.psp.civcom.dev | pl.gov.psp.civcom.dev.ios.dev |
| Release | pl.gov.psp.civcom | group.pl.gov.psp.civcom | pl.gov.psp.civcom.ios.prod |

Extensions append `.nse` and `.shareextension` to the application ID.
Keychain group is `$(AppIdentifierPrefix)$(BASE_BUNDLE_IDENTIFIER)`.
Apple Developer organization Team ID L643PDVV68 was independently inspected.
App IDs, capabilities, signing profiles, certificates and APNs credentials still require provisioning.
Push token uses Base64 (Sygnal `convert_device_token_to_hex: true`).
Gateway: https://push.soia.info/_matrix/push/v1/notify with event_id_only.
Every displayed notification uses CIVCOM / Nowa wiadomość; room/event IDs remain for tap routing.

## Authentication and scope

Only soia.info and https://matrix.soia.info are accepted, including QR, provisioning and session restoration.
OAuth authorization origin is https://auth.soia.info, discovered and validated by the upstream SDK.
Client URI: https://civcom.soia.info/apps/ios.
Callback: https://civcom.soia.info/oauth/ios/{application-ID}.
Associated domains: applinks:civcom.soia.info and webcredentials:civcom.soia.info.
Logo: https://civcom.soia.info/znak.svg.
Terms/privacy URLs `/terms` and `/privacy` must be live and approved before release.
Self-registration must also be disabled in MAS/Synapse administrative policy.

Chat, groups, encrypted files, audio/video attachments, verification and recovery remain.
Calls and maps are excluded from v1; no CallKit/PushKit/RTC or CLLocationManager initialization.
No analytics or remote error reporting, regardless of consent or generated Secrets.
Upstream reporting libraries remain dependencies for source compatibility but are not initialized.
Website artwork and light/dark palette are bundled; Polish custom text is in Untranslated.strings.

## Build and acceptance

Install Xcode 26.6 or later and the official XcodeGen/SwiftGen/Sourcery/SwiftFormat/SwiftLint tools.
Run `xcodegen`, then `xcodebuild -project ElementX.xcodeproj -scheme ElementX -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /external/cache CODE_SIGNING_ALLOWED=NO build`.
Select destination without forcing `-sdk iphonesimulator`, which misbuilds host macros.
Run UnitTests/CIVCOMPolicyTests with an iOS 26 simulator; run policy checks as in CIVCOM checks workflow.
Use external TMPDIR, DerivedData, SwiftPM and module caches on storage-constrained machines.
The new workflow never signs, publishes, uploads reports or uses organization secrets.
Removed Element-specific workflows are preserved at the provenance SHA in upstream Git history.

Publication requires independent native login, cross-platform E2EE/recovery/media tests, signed physical-device APNs delivery,
negative tests for arbitrary servers/calls/map events/deep links, dark/light/a11y review,
AGPL corresponding source and dependency distribution clearance, and approved store/privacy disclosures.
An unsigned compile or policy check does not satisfy those gates.
