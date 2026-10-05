// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

@testable import ElementX
import MatrixRustSDK
import SwiftUI
import Testing

struct CIVCOMBootstrapTests {
    @Test func restorationCopiesBothSDKAPIInputsWithoutChangingStoredCryptoContext() throws {
        for storedURL in ["soia.info", "https://matrix.soia.info", "https://matrix.soia.info/"] {
            let session = MatrixRustSDK.Session(accessToken: "synthetic-token", refreshToken: "synthetic-refresh", userId: "@fixture:soia.info", deviceId: "DEVICE",
                                                homeserverUrl: storedURL, oauthData: "{\"client_id\":\"synthetic\"}", slidingSyncVersion: .native)
            let original = RestorationToken(session: session, sessionDirectories: .init(), passphrase: "synthetic-key", pusherNotificationClientIdentifier: nil)
            let input = try ClientFactory.normalizedRestorationSession(for: .init(userID: session.userId, restorationToken: original))
            #expect(input.homeserverUrl == "https://matrix.soia.info")
            #expect(input.userId == session.userId && input.deviceId == session.deviceId)
            #expect(input.accessToken == session.accessToken && input.refreshToken == session.refreshToken && input.oauthData == session.oauthData)
            #expect(original.session.homeserverUrl == storedURL && original.passphrase == "synthetic-key")
        }
    }
    
    @Test func foreignRestorationStopsBeforeAnySDKClientBuild() async throws {
        let session = MatrixRustSDK.Session(accessToken: "synthetic-token", refreshToken: nil, userId: "@foreign:matrix.org", deviceId: "DEVICE",
                                            homeserverUrl: "https://matrix.soia.info", oauthData: nil, slidingSyncVersion: .native)
        let token = RestorationToken(session: session, sessionDirectories: .init(), passphrase: "synthetic-key", pusherNotificationClientIdentifier: nil)
        let credentials = KeychainCredentials(userID: session.userId, restorationToken: token)
        await #expect(throws: CIVCOMProviderError.self) {
            _ = try await ClientFactory().makeAppClient(credentials: credentials, clientSessionDelegate: KeychainControllerMock(.init()), appSettings: .volatile(), appHooks: AppHooks())
        }
    }
    
    @Test func officialInputsMapToOneAPIWithoutDiscoveryFallback() throws {
        for input in ["soia.info", "https://matrix.soia.info", "https://matrix.soia.info/"] {
            #expect(try CIVCOMPolicy.authenticationAPI(for: input).absoluteString == "https://matrix.soia.info")
        }
        for input in ["matrix.org", "http://matrix.soia.info", "https://matrix.soia.info.evil", "https://user@matrix.soia.info"] {
            #expect(throws: CIVCOMProviderError.self) { try CIVCOMPolicy.authenticationAPI(for: input) }
        }
    }
    
    @Test(.enabled(if: ProcessInfo.processInfo.environment["CIVCOM_LIVE_BOOTSTRAP"] == "1"))
    func officialAliasBootstrapsAtApprovedAPI() async throws {
        #expect(try await CIVCOMOwnedOAuthMetadataProvider().verifiedIssuer() == CIVCOMOAuthPolicy.issuer)
        let client = try await ClientFactory().makeInMemoryClient(serverNameOrBaseURL: "soia.info",
                                                                  clientSessionDelegate: KeychainController(service: .tests, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier),
                                                                  appSettings: .volatile(),
                                                                  appHooks: AppHooks())
        let baseURL = try #require(URL(string: client.homeserver()))
        #expect(baseURL.scheme == "https" && baseURL.host == "matrix.soia.info")
        let details = await client.homeserverLoginDetails()
        #expect(details.supportsOauthLogin())
    }
}
