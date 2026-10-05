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
New OAuth/QR preflight requires issuer https://auth.soia.info/ and owned HTTPS metadata endpoints before SDK authorization/scan; SDK cached/refetched issuer binding is not exposed or proven.
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

## SOIA visual identity

Canonical reference: KGPSP/soia-branding at 049915d7a6651c6beec9bfa1f2407b9f679bf937.
The default operational theme is dark; saved light/system choices remain. Compound and UIKit share canonical semantic colors, with blue links/focus and green encryption status.
The existing transmitter SVG remains byte-identical, without added chrome. Onboarding uses system Avenir Next Condensed when available (native Dynamic Type, SF fallback), SF body, monospaced metadata, a flat 4pt primary sign-in and neutral secondary QR. No font files or invented wordmark are distributed.
Native palette/contrast and persistence tests precede the visual change. Actual dark/light and largest accessibility text captures are kept in reviewer evidence.

## Managed authentication boundary (narrow proposal B)

Only approved aliases reach https://matrix.soia.info; restoration also requires an owned soia.info MXID. Accepted stored aliases are normalized in a local Session value copy to the actual API for both the SDK builder and restoreSession input; stored crypto/token fields are untouched. New OAuth and QR preflight owned Matrix v1/auth_metadata for exact issuer https://auth.soia.info/ and owned HTTPS endpoints. Normal preflight precedes SDK authorization; QR preflight precedes SDK client creation/scan. Callback origin/path checks remain. The upstream SDK and keychain/crypto-directory/token mechanics remain unchanged; no legacy witness hard gate, new reauthentication state, quarantine or automatic SDK/device migration is introduced.
Pinned FFI exposes no binding of SDK cached/refetched issuer metadata to preflight: NOT_PROVEN, not a formal hardpin. This relies on the controlled Matrix/MAS backend; a new CIVCOM app/group namespace has no actual migrated legacy accounts. Account login, offline authenticated history/recovery and physical APNs remain NOT_RUN.
The generic v1 NSE derives receiverID only from a matching active owned local credential; it creates no SDK client, fetch/decrypt/read-state work, refresh writer, call/map/preview/action. Foreground validation handles room/event routing. SDK event filtering and fresh server authentication in NSE are not provided/proven, so unsupported/redacted/read events may produce a generic alert and unread-badge parity is not claimed. Test/physical delivery acceptance remains separate.
CI executes full UnitTests rather than selective masking. UnitTests uses explicit English locale for inherited string assertions; Polish actual UI captures are separate. The live public bootstrap/preflight probe remains opt-in and never performs DCR/account login.
