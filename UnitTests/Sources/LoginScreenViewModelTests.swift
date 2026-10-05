//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDKMocks
import Testing

@MainActor
struct LoginScreenViewModelTests {
    var viewModel: LoginScreenViewModelProtocol!
    var context: LoginScreenViewModelType.Context {
        viewModel.context
    }
    
    var clientFactory: ClientFactoryMock!
    var service: AuthenticationServiceProtocol!
    
    @Test
    mutating func basicServer() async throws {
        // Given the view model configured for a basic server soia.info that only supports password authentication.
        try await setupViewModel()
        
        // Then the view state should be updated with the homeserver and show the login form.
        #expect(context.viewState.homeserver == .init(accountProvider: .generic("soia.info"), loginMode: .password),
                "The homeserver data should should match the new homeserver.")
        #expect(context.viewState.loginMode == .password,
                "The login form should be shown.")
    }
    
    @Test
    mutating func usernameWithEmptyPassword() async throws {
        // Given a form with an empty username and password.
        try await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a username without a password.
        context.username = "bob"
        context.password = ""
        
        // Then the credentials should be considered invalid.
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
    }
    
    @Test
    mutating func emptyUsernameWithPassword() async throws {
        // Given a form with an empty username and password.
        try await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a password without a username.
        context.username = ""
        context.password = "12345678"
        
        // Then the credentials should be considered invalid.
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
    }
    
    @Test
    mutating func validCredentials() async throws {
        // Given a form with an empty username and password.
        try await setupViewModel()
        #expect(context.password.isEmpty,
                "The initial value for the password should be empty.")
        #expect(context.username.isEmpty,
                "The initial value for the username should be empty.")
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be invalid.")
        #expect(!context.viewState.canSubmit,
                "The form should be blocked for submission.")
        
        // When entering a username and an 8-character password.
        context.username = "bob"
        context.password = "12345678"
        
        // Then the credentials should be considered valid.
        #expect(context.viewState.hasValidCredentials,
                "The credentials should be valid when the username and password are valid.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
    }
    
    @Test
    mutating func loadingServerWithoutPassword() async throws {
        // Given a form with valid credentials.
        try await setupViewModel()
        context.username = "@bob:soia.info"
        #expect(!context.viewState.hasValidCredentials,
                "The credentials should be not be valid without a password.")
        #expect(!context.viewState.isLoading,
                "The view shouldn't start in a loading state.")
        #expect(!context.viewState.canSubmit,
                "The form should not be submittable.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.isLoading),
                                        transitionValues: [true, false])
        context.send(viewAction: .parseUsername)
        
        // Then the view state should represent the loading but never allow submitting to occur.
        try await deferred.fulfill()
        #expect(!context.viewState.isLoading,
                "The view should be back in a loaded state.")
        #expect(!context.viewState.canSubmit,
                "The form should still not be submittable.")
    }
    
    @Test
    mutating func loadingServerWithPasswordEntered() async throws {
        // Given a form with valid credentials.
        try await setupViewModel()
        context.username = "@bob:soia.info"
        context.password = "12345678"
        #expect(context.viewState.hasValidCredentials,
                "The credentials should be valid.")
        #expect(!context.viewState.isLoading,
                "The view shouldn't start in a loading state.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
        
        // When updating the view model whilst loading a homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.canSubmit),
                                        transitionValues: [false, true])
        context.send(viewAction: .parseUsername)
        
        // Then the view should be blocked from submitting while loading and then become unblocked again.
        try await deferred.fulfill()
        #expect(!context.viewState.isLoading,
                "The view should be back in a loaded state.")
        #expect(context.viewState.canSubmit,
                "The form should be ready to submit.")
    }
    
    @Test
    mutating func oAuthServer() async throws {
        // Given the official provider configured for OAuth.
        try await setupViewModel(supportsOAuth: true)
        
        // When entering a username for a user on a homeserver with OAuth.
        let deferred = deferFulfillment(viewModel.actions) {
            $0.isConfiguredForOAuth
        }
        context.username = "@bob:soia.info"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()
        
        // Then the view state should be updated with the homeserver and show the OAuth button.
        #expect(context.viewState.loginMode.supportsOAuthFlow,
                "The OAuth button should be shown.")
    }
    
    @Test
    mutating func unsupportedServer() async throws {
        // Given the screen configured for soia.info
        try await setupViewModel()
        #expect(context.alertInfo == nil,
                "There shouldn't be an alert when the screen loads.")
        
        // When entering a username for an unsupported homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) {
            $0 != nil
        }
        context.username = "@bob:server.net"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()
        
        // Then the view state should be updated to show an alert.
        #expect(context.alertInfo?.id == .unknown,
                "An alert should be shown to the user.")
    }
    
    @Test
    mutating func foreignProviderCannotTriggerElementProOrSDK() async throws {
        // Given the screen configured for soia.info
        try await setupViewModel()
        #expect(context.alertInfo == nil,
                "There shouldn't be an alert when the screen loads.")
        
        // When entering a username for an unsupported homeserver.
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) {
            $0 != nil
        }
        context.username = "@bob:secure.gov"
        context.send(viewAction: .parseUsername)
        try await deferred.fulfill()
        
        // Then the view state should be updated to show an alert.
        #expect(context.alertInfo?.id == .unknown,
                "An alert should be shown to the user.")
    }
    
    @Test
    mutating func loginHint() async throws {
        try await setupViewModel(loginHint: "")
        #expect(context.username == "")
        
        try await setupViewModel(loginHint: "alice")
        #expect(context.username == "alice")
        
        try await setupViewModel(loginHint: "mxid:@alice:soia.info")
        #expect(context.username == "@alice:soia.info")
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(loginHint: String? = nil, supportsOAuth: Bool = false) async throws {
        let appSettings = AppSettings.volatile()
        
        var configuration = ClientFactoryMock.Configuration()
        configuration.homeserverClients["soia.info"] = ClientSDKMock(.init(serverName: "soia.info", homeserverURL: "https://matrix.soia.info", oAuthLoginURL: supportsOAuth ? "https://auth.soia.info/authorize" : nil,
                                                                           supportsOAuthCreatePrompt: false, supportsPasswordLogin: !supportsOAuth))
        clientFactory = ClientFactoryMock(configuration)
        service = AuthenticationService(userSessionStore: UserSessionStoreMock(.init()),
                                        encryptionKeyProvider: EncryptionKeyProvider(),
                                        classicAppManager: nil,
                                        clientFactory: clientFactory,
                                        appSettings: appSettings,
                                        appHooks: AppHooks(), oauthMetadataProvider: CIVCOMTestOAuthMetadataProvider())
        
        try await service.configure(for: "soia.info", flow: .login).get()
        
        viewModel = LoginScreenViewModel(authenticationService: service,
                                         loginHint: loginHint,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: appSettings)
    }
}
