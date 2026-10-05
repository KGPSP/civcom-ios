// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

@testable import ElementX
import SwiftUI
import Testing

struct CIVCOMBootstrapTests {
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
