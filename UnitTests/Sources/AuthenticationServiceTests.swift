//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct AuthenticationServiceTests {
    var client: ClientSDKMock!
    var encryption: EncryptionSDKMock!
    var userSessionStore: UserSessionStoreMock!
    var encryptionKeyProvider: MockEncryptionKeyProvider!
    var service: AuthenticationService!
    
    @Test
    mutating func passwordLogin() async throws {
        try await setup(serverNameOrBaseURL: "example.com")
        
        switch await service.configure(for: "soia.info", flow: .login) {
        case .success:
            break
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .init(accountProvider: .generic("soia.info"), loginMode: .password))
        
        switch await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil) {
        case .success:
            #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
            #expect(userSessionStore.userSessionForSessionDirectoriesPassphraseCallsCount == 1)
            #expect(userSessionStore.userSessionForSessionDirectoriesPassphraseReceivedArguments?.passphrase ==
                encryptionKeyProvider.generateKey().base64EncodedString())
        case .failure(let error):
            Issue.record("Unexpected failure: \(error)")
        }
    }
    
    @Test
    mutating func configureLoginWithOAuth() async throws {
        try await setup()
        
        try await service.configure(for: "soia.info", flow: .login).get()
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .init(accountProvider: .generic("soia.info"), loginMode: .oAuth(supportsCreatePrompt: true)))
    }
    
    @Test
    mutating func configureRegisterWithOAuth() async throws {
        try await setup()
        let result = await service.configure(for: "soia.info", flow: .register)
        guard case .failure(.registrationNotSupported) = result else { Issue.record("Registration allowed"); return }
        #expect(service.flow == .login)
    }
    
    @Test
    mutating func configureRegisterNoSupport() async throws {
        let serverNameOrBaseURL = "example.com"
        try await setup(serverNameOrBaseURL: serverNameOrBaseURL)
        
        try await #require(throws: AuthenticationServiceError.registrationNotSupported) {
            try await service.configure(for: serverNameOrBaseURL, flow: .register).get()
        }
        
        #expect(service.flow == .login)
        #expect(service.homeserver.value == .init(accountProvider: .managed(serverName: "soia.info", baseURL: "https://matrix.soia.info"),
                                                  loginMode: .unknown))
    }
    
    @Test
    mutating func classicAppAccountSecretsBundleIsUsed() async throws {
        // Given an authentication service with an Element Classic account for Alice.
        try await setup(classicAppAccounts: [.mockAlice])
        try await service.configure(for: "soia.info", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .complete)
        
        // When logging in as Alice.
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then Alice's secrets from Element Classic should be imported.
        #expect(encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    @Test
    mutating func classicAppAccountSecretsBundleIsIgnoredWhenUnavailable() async throws {
        // Given an authentication service with an Element Classic account for Alice
        // which isn't configured with any available secrets.
        try await setup(classicAppAccounts: [.mockAlice], availableSecrets: .unavailable)
        try await service.configure(for: "soia.info", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .unavailable)
        
        // When logging in as Alice.
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then an attempt to import Alice's secrets from Element Classic must not be made.
        #expect(!encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    @Test
    mutating func classicAppAccountSecretsBundleIsIgnoredForDifferentUser() async throws {
        // Given an authentication service with an Element Classic account for Dan.
        try await setup(classicAppAccounts: [.mockDan])
        try await service.configure(for: "soia.info", flow: .login).get()
        #expect(service.flow == .login)
        #expect(service.classicAppAccount?.state.availableSecrets == .complete)
        
        // When logging in as Alice
        _ = try await service.login(username: "alice", password: "12345678", initialDeviceName: nil, deviceID: nil).get()
        #expect(client.loginUsernamePasswordInitialDeviceNameDeviceIdCallsCount == 1)
        
        // Then Dan's secrets from Element Calssic should not be imported into Alice's client.
        #expect(!encryption.importSecretsBundleSecretsBundleCalled)
    }
    
    @Test mutating func foreignIssuerStopsOAuthBeforeSDKAuthorization() async throws {
        try await setup(issuer: "https://evil.example/")
        try await service.configure(for: "soia.info", flow: .login).get()
        guard case .failure = await service.urlForOAuthLogin(loginHint: nil) else { Issue.record("Foreign issuer accepted"); return }
        #expect(!client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCalled)
        #expect(!userSessionStore.userSessionForSessionDirectoriesPassphraseCalled)
    }
    
    @Test mutating func ownedIssuerAllowsSDKAuthorization() async throws {
        try await setup()
        try await service.configure(for: "soia.info", flow: .login).get()
        _ = try await service.urlForOAuthLogin(loginHint: nil).get()
        #expect(client.urlForOauthOauthConfigurationPromptLoginHintDeviceIdAdditionalScopesCallsCount == 1)
    }
    
    @Test mutating func foreignIssuerStopsQRBeforeClientAndScan() async throws {
        try await setup(issuer: "https://evil.example/")
        let handler = LoginWithQrCodeHandlerSDKMock()
        client.newLoginWithQrCodeHandlerOauthConfigurationReturnValue = handler
        let publisher = service.loginWithQRCode(data: syntheticQR())
        await #expect(throws: AuthenticationServiceError.self) {
            for try await _ in publisher.values { }
        }
        #expect(!handler.scanQrCodeDataProgressListenerCalled)
        #expect(!userSessionStore.userSessionForSessionDirectoriesPassphraseCalled)
    }
    
    @Test mutating func ownedIssuerAllowsQRScanAndSession() async throws {
        try await setup()
        let handler = LoginWithQrCodeHandlerSDKMock()
        client.newLoginWithQrCodeHandlerOauthConfigurationReturnValue = handler
        var signedIn = false
        for try await progress in service.loginWithQRCode(data: syntheticQR()).values {
            if case .signedIn = progress {
                signedIn = true; break
            }
        }
        #expect(signedIn)
        #expect(handler.scanQrCodeDataProgressListenerCallsCount == 1)
        #expect(userSessionStore.userSessionForSessionDirectoriesPassphraseCalled)
    }
    
    private func syntheticQR() -> Data {
        // MSC4108 at pinned SDK85bad975: prefix/version/reciprocate/key/length-prefixed URLs and server name.
        var data = Data("MATRIX".utf8) + Data([2, 4]) + Data(repeating: 1, count: 32)
        for field in ["https://matrix.soia.info/_synapse/client/rendezvous/synthetic", "soia.info"] {
            let value = Data(field.utf8)
            data.append(contentsOf: [UInt8(value.count >> 8), UInt8(value.count & 255)])
            data.append(value)
        }
        return data
    }
    
    // MARK: - Helpers
    
    private mutating func setup(serverNameOrBaseURL: String = "soia.info",
                                classicAppAccounts: [ClassicAppAccount] = [],
                                availableSecrets: ClassicAppAccount.AvailableSecrets = .complete, issuer: String = CIVCOMOAuthPolicy.issuer) async throws {
        var configuration: ClientFactoryMock.Configuration = .init()
        if serverNameOrBaseURL == "example.com" {
            configuration.homeserverClients["soia.info"] = configuration.homeserverClients["example.com"]
        }
        let clientFactory = ClientFactoryMock(configuration)
        client = configuration.homeserverClients["soia.info"]
        encryption = EncryptionSDKMock()
        client.encryptionReturnValue = encryption
        
        userSessionStore = UserSessionStoreMock(.init())
        encryptionKeyProvider = MockEncryptionKeyProvider()
        
        let ownedClassicAccounts = classicAppAccounts.map { account in
            ClassicAppAccount(userID: account.userID.replacingOccurrences(of: ":matrix.org", with: ":soia.info"),
                              displayName: account.displayName, avatarURL: account.avatarURL,
                              serverName: "soia.info", homeserverURL: "https://matrix.soia.info",
                              cryptoStoreURL: account.cryptoStoreURL, cryptoStorePassphrase: account.cryptoStorePassphrase,
                              accessToken: account.accessToken)
        }
        let classicAppManager = ClassicAppManagerMock(.init(accounts: ownedClassicAccounts,
                                                            availableSecrets: availableSecrets,
                                                            secretsBundle: SecretsBundleWithUserIdSDKMock()))
        
        service = AuthenticationService(userSessionStore: userSessionStore,
                                        encryptionKeyProvider: encryptionKeyProvider,
                                        classicAppManager: classicAppManager,
                                        clientFactory: clientFactory,
                                        appSettings: .volatile(),
                                        appHooks: AppHooks(), oauthMetadataProvider: CIVCOMTestOAuthMetadataProvider(issuer: issuer))
        
        if let classicAppAccount = service.classicAppAccount {
            await service.setupClassicAppAccountState()
            try #require(classicAppAccount.state.isServerSupported == true)
            try #require(classicAppAccount.state.availableSecrets == availableSecrets)
        }
    }
}

struct MockEncryptionKeyProvider: EncryptionKeyProviderProtocol {
    private let key = "12345678"
    
    func generateKey() -> Data {
        Data(key.utf8)
    }
}
