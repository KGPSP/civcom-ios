//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @Bindable var context: AuthenticationStartScreenViewModel.Context
    
    var body: some View {
        if case let .welcomeBack(classicAppAccount) = context.viewState.classicAppMode,
           classicAppAccount.state.isServerSupported != false {
            AuthenticationClassicAppAccountView(context: context, classicAppAccount: classicAppAccount)
        } else {
            standardContent
        }
    }
    
    var standardContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 24)
                    content
                        .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)
                    Spacer(minLength: 24)
                    buttons
                    serviceFooter
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .readableFrame()
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.compound.bgCanvasDefault)
        .navigationBarHidden(context.viewState.classicAppMode == nil)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    var content: some View {
        VStack(spacing: 16) {
            AuthenticationStartLogo(hideBrandChrome: true, isOnGradient: false)
            Text(UntranslatedL10n.screenCivcomWelcomeTitleIos)
                .font(.civcomHeading(size: 36, relativeTo: .largeTitle))
                .tracking(2)
                .foregroundStyle(Color.compound.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(UntranslatedL10n.screenCivcomTaglineIos)
                .font(.civcomHeading(size: 17, relativeTo: .headline))
                .tracking(1.5)
                .foregroundStyle(Color.compound.textSecondary)
            Text(UntranslatedL10n.screenCivcomWelcomeMessageIos)
                .font(.compound.bodyLG)
                .foregroundStyle(Color.compound.textPrimary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var serviceFooter: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color.compound.separatorPrimary)
                .frame(height: 1)
            Text(UntranslatedL10n.screenCivcomServiceFooterIos)
                .font(.system(.caption, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color.compound.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            versionText
                .font(.system(.caption, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(Color.compound.textSecondary)
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
        }
        .padding(.top, 8)
    }
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 12) {
            Button { context.send(viewAction: .login) } label: {
                Text(UntranslatedL10n.screenCivcomSignInIos)
            }
            .buttonStyle(CIVCOMButtonStyle(kind: .primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)
            
            if context.viewState.showQRCodeLoginButton {
                Button { context.send(viewAction: .loginWithQR) } label: {
                    Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
                }
                .buttonStyle(CIVCOMButtonStyle(kind: .secondary))
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            }
        }
    }
    
    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if case let .otherOptions(classicAppAccount) = context.viewState.classicAppMode {
                ToolbarButton(role: .close) {
                    context.send(viewAction: .closeOtherOptions(classicAppAccount))
                }
            }
        }
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")
    static let classicAppViewModel = makeViewModel(hasClassicAppAccount: true)
    
    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
        
        ElementNavigationStack {
            AuthenticationStartScreen(context: classicAppViewModel.context)
        }
        .previewDisplayName("Classic App")
    }
    
    static func makeViewModel(provisionedServerName: String? = nil, hasClassicAppAccount: Bool = false) -> AuthenticationStartScreenViewModel {
        let classicAppAccount = ClassicAppAccount.mockDan
        classicAppAccount.state.isServerSupported = true
        classicAppAccount.state.availableSecrets = .complete
        let classicAppManager: ClassicAppManagerMock? = hasClassicAppAccount ? .init(.init(accounts: [classicAppAccount])) : nil
        
        return AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock(classicAppManager: classicAppManager),
                                                  provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                                  isBugReportServiceEnabled: true,
                                                  appMediator: AppMediatorMock(),
                                                  appSettings: .volatile(),
                                                  mediaProvider: MediaProviderMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
}
