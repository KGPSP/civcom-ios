// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
@testable import ElementX
import SwiftUI
import Testing

struct CIVCOMOAuthPolicyTests {
    @Test func exactOwnedIssuerAndEndpoints() throws {
        #expect(try CIVCOMOAuthPolicy.validateMetadata(metadata(issuer: "https://auth.soia.info/")) == CIVCOMOAuthPolicy.issuer)
        for value in ["https://evil.example/", "http://auth.soia.info/", "https://auth.soia.info/foreign", "https://auth.soia.info.evil/"] {
            #expect(throws: CIVCOMOAuthPolicy.Failure.self) { try CIVCOMOAuthPolicy.validateMetadata(metadata(issuer: value)) }
        }
        #expect(throws: CIVCOMOAuthPolicy.Failure.self) { try CIVCOMOAuthPolicy.validateMetadata(metadata(issuer: CIVCOMOAuthPolicy.issuer, token: "https://evil.example/token")) }
    }
    
    @Test func onlyOwnedStoredAccountsCanReachRestoration() {
        #expect(CIVCOMPolicy.allowsStoredAccount(userID: "@fixture:soia.info", homeserverURL: "https://matrix.soia.info"))
        for userID in ["@fixture:matrix.org", "fixture:soia.info", "@:soia.info", "@fixture:soia.info.evil", "@bad name:soia.info"] {
            #expect(!CIVCOMPolicy.allowsStoredAccount(userID: userID, homeserverURL: "https://matrix.soia.info"))
        }
        for server in ["https://elsewhere.invalid", "soia.info", "http://matrix.soia.info", "https://matrix.soia.info/path"] {
            #expect(!CIVCOMPolicy.allowsStoredAccount(userID: "@fixture:soia.info", homeserverURL: server))
        }
    }
    
    private func metadata(issuer: String, token: String = "https://auth.soia.info/oauth2/token") throws -> Data {
        try JSONSerialization.data(withJSONObject: ["issuer": issuer, "authorization_endpoint": "https://auth.soia.info/authorize", "token_endpoint": token,
                                                    "registration_endpoint": "https://auth.soia.info/oauth2/registration", "jwks_uri": "https://auth.soia.info/oauth2/keys.json"])
    }
}

struct CIVCOMTestOAuthMetadataProvider: CIVCOMOAuthMetadataProvider {
    var issuer = CIVCOMOAuthPolicy.issuer
    func verifiedIssuer() async throws -> String {
        issuer
    }
}
