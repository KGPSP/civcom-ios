//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDKMocks
import SwiftUI
import Testing

@MainActor
struct ServerSelectionScreenViewModelTests {
    var appSettings: AppSettings!
    var client: ClientSDKMock!
    var clientFactory: ClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    var viewModel: ServerSelectionScreenViewModelProtocol!
    var context: ServerSelectionScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test mutating func ownedProviderCanContinueOAuth() async throws {
        try setup(authenticationFlow: .login)
        context.serverNameOrBaseURL = "soia.info"
        let continued = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await continued.fulfill()
        #expect(clientFactory.makeAuthenticationClientServerNameOrBaseURLSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksReceivedArguments?.serverNameOrBaseURL == "soia.info")
    }
    
    @Test mutating func ownedMatrixIDUsesOwnedProvider() async throws {
        try setup(authenticationFlow: .login)
        context.serverNameOrBaseURL = "@fixture:soia.info"
        let continued = deferFulfillment(viewModel.actions) { $0.isContinueWithOAuth }
        context.send(viewAction: .confirm)
        try await continued.fulfill()
        #expect(service.homeserver.value.accountProvider.serverNameOrBaseURL == "soia.info")
    }
    
    @Test mutating func foreignProviderStopsBeforeSDK() async throws {
        try setup(authenticationFlow: .login)
        context.serverNameOrBaseURL = "matrix.org"
        let rejected = deferFulfillment(context.observe(\.viewState.footerErrorMessage)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await rejected.fulfill()
        #expect(clientFactory.makeAuthenticationClientServerNameOrBaseURLSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
        #expect(service.homeserver.value.loginMode == .unknown)
    }
    
    @Test mutating func registrationStopsEvenForOwnedProvider() async throws {
        try setup(authenticationFlow: .register)
        context.serverNameOrBaseURL = "soia.info"
        let rejected = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
        context.send(viewAction: .confirm)
        try await rejected.fulfill()
        #expect(context.alertInfo?.id == .registrationAlert)
        #expect(clientFactory.makeAuthenticationClientServerNameOrBaseURLSessionDirectoriesPassphraseClientSessionDelegateAppSettingsAppHooksCallsCount == 0)
    }
    
    private mutating func setup(authenticationFlow: AuthenticationFlow,
                                mode: ServerSelectionScreenMode = .userInput) throws {
        appSettings = AppSettings.volatile()
        
        let factoryConfiguration = ClientFactoryMock.Configuration()
        // matrix.org: OAuth. example.com: password only. server.net: no login. secure.gov: OAuth + Element Pro required.
        client = factoryConfiguration.homeserverClients["soia.info"]
        clientFactory = ClientFactoryMock(factoryConfiguration)
        
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(.init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        classicAppManager: nil,
                                        clientFactory: clientFactory,
                                        appSettings: appSettings,
                                        appHooks: AppHooks(), oauthMetadataProvider: CIVCOMTestOAuthMetadataProvider())
        
        viewModel = ServerSelectionScreenViewModel(authenticationService: service,
                                                   mode: mode,
                                                   authenticationFlow: authenticationFlow,
                                                   appSettings: appSettings,
                                                   homeserverHistoryManager: HomeserverHistoryManager(appSettings: appSettings),
                                                   userIndicatorController: UserIndicatorControllerMock())
        
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        viewModel.context.send(viewAction: .updateWindow(UIWindow(windowScene: scene)))
    }
}

private extension ServerSelectionScreenViewModelAction {
    var isContinueWithOAuth: Bool {
        switch self {
        case .continueWithOAuth: true
        default: false
        }
    }
    
    var isContinueWithPassword: Bool {
        switch self {
        case .continueWithPassword: true
        default: false
        }
    }
}
