// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

import Compound
@testable import ElementX
import SwiftUI
import Testing
import UserNotifications

struct CIVCOMPolicyTests {
    @Test func officialProviderOnly() async {
        let settings = AppSettings.volatile()
        #expect(!settings.allowOtherAccountProviders)
        #expect(!settings.showCreateAccountButton)
        #expect(settings.defaultAccountProvider == .managed(serverName: "soia.info", baseURL: "https://matrix.soia.info"))
        let service = AuthenticationService.mock
        let foreign = await service.configure(for: "matrix.org", flow: .login)
        guard case .failure(.invalidServerNameOrBaseURL) = foreign else { Issue.record("Foreign provider accepted"); return }
        let registration = await service.configure(for: "soia.info", flow: .register)
        guard case .failure(.registrationNotSupported) = registration else { Issue.record("Registration accepted"); return }
    }
    
    @Test func nativePushAndOAuthIdentity() throws {
        let settings = AppSettings.volatile()
        #expect(settings.pusherAppID == "pl.gov.psp.civcom.dev.ios.dev")
        #expect(settings.pushGatewayNotifyEndpoint.absoluteString == "https://push.soia.info/_matrix/push/v1/notify")
        let oauth = settings.oAuthConfiguration
        #expect(oauth.redirectURI.absoluteString == "https://civcom.soia.info/oauth/ios/pl.gov.psp.civcom.dev")
        for url in [oauth.clientURI, oauth.logoURI, oauth.tosURI, oauth.policyURI] {
            #expect(url.scheme == "https" && url.host == "civcom.soia.info")
        }
        let payload = APNSPayload(aps: APSInfo(mutableContent: 1, alert: APSAlert(locKey: nil, locArgs: [])), pusherNotificationClientIdentifier: "test-client")
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any]
        let alert = (json?["aps"] as? [String: Any])?["alert"] as? [String: Any]
        #expect(alert?["title"] as? String == "CIVCOM")
        #expect(alert?["body"] as? String == "Nowa wiadomość")
        #expect(alert?["loc-key"] == nil)
        #expect(UntranslatedL10n.screenCivcomSignInIos == "Zaloguj się")
    }
    
    @Test func cannotOverrideReportingOrFeatureScope() {
        let settings = AppSettings.volatile()
        settings.analyticsConsentState = .optedIn
        settings.nativeCallEnabled = true
        #expect(settings.analyticsConfiguration == nil)
        #expect(settings.bugReportSentryURL == nil)
        #expect(settings.bugReportSentryRustURL == nil)
        #expect(!settings.canPromptForAnalytics)
        #expect(!CIVCOMPolicy.callsEnabled)
        #expect(!CIVCOMPolicy.mapsEnabled)
    }
    
    @Test func excludedServicesCannotStart() async {
        let calls = CIVCOMDisabledCallService()
        let room = JoinedRoomProxyMock(.init())
        #expect(calls.handleNativeCallRequest(roomProxy: room, isVoiceCall: false))
        #expect(calls.nativeCallController == nil)
        await calls.setupCallSession(roomID: "!room:soia.info", roomDisplayName: "Room", isVideo: true)
        #expect(calls.ongoingCallRoomIDPublisher.value == nil)
        let location = CIVCOMDisabledLocationManager()
        #expect(!location.requestAlwaysAuthorizationIfPossible())
        let result = await location.startLiveLocation(roomID: "!room:soia.info", duration: .seconds(60))
        guard case .failure(.startFailed) = result else { Issue.record("Location service started"); return }
    }
    
    @Test func hostileProvisioningAndCallbackLinks() throws {
        let settings = AppSettings.volatile()
        let parser = AppRouteURLParser(appSettings: settings)
        #expect(try parser.route(from: #require(URL(string: "https://civcom.soia.info/?account_provider=matrix.org"))) == nil)
        #expect(try parser.route(from: #require(URL(string: "http://civcom.soia.info/?account_provider=soia.info"))) == nil)
        #expect(try parser.route(from: #require(URL(string: settings.oAuthRedirectURL.absoluteString + ".attacker?code=x"))) == nil)
        #expect(try parser.route(from: #require(URL(string: settings.oAuthRedirectURL.absoluteString + "?code=x&state=y"))) != nil)
    }
    
    @Test func primaryButtonTextHasDarkModeContrast() {
        DefaultCompoundHook().override(colors: Color.compound, uiColors: UIColor.compound)
        let text = UIColor.compound.textOnSolidPrimary.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        #expect(text.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        #expect(red == 1 && green == 1 && blue == 1 && alpha == 1)
    }
    
    @Test func genericNotificationsPreserveRoutingWithoutPreview() {
        let content = UNMutableNotificationContent()
        content.title = "Sender"
        content.subtitle = "Room"
        content.body = "Secret body"
        content.userInfo = ["room_id": "!room:soia.info", "event_id": "$event"]
        CIVCOMPolicy.redact(content)
        #expect(content.title == "CIVCOM")
        #expect(content.subtitle.isEmpty)
        #expect(content.body == "Nowa wiadomość")
        #expect(content.attachments.isEmpty)
        #expect(content.userInfo["room_id"] as? String == "!room:soia.info")
    }
}
