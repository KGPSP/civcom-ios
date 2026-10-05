//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import NotificationCenter
import Testing

@MainActor
final class NotificationManagerTests {
    var notificationManager: NotificationManager!
    private let clientProxy = ClientProxyMock(.init(userID: "@fixture:soia.info"))
    private lazy var mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
    private var notificationCenter: UserNotificationCenterMock!
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private var tappedContent: UNNotificationContent?
    private var registerForRemoteNotificationsDelegateCalled: (() -> Void)?
    private let appSettings: AppSettings
    
    init() {
        appSettings = AppSettings.volatile()
        clientProxy.pusherNotificationClientIdentifier = "48df8697ad56e8c97b385a49463b1674db8c60a358d08c1241eb06329f46d855"
        notificationCenter = UserNotificationCenterMock()
        notificationCenter.requestAuthorizationOptionsReturnValue = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationCenter.notificationSettingsClosure = { await UNUserNotificationCenter.current().notificationSettings() }
        
        notificationManager = NotificationManager(notificationCenter: notificationCenter, appSettings: appSettings)
        notificationManager.start()
        notificationManager.setUserSession(mockUserSession)
    }
    
    isolated deinit {
        notificationCenter = nil
        notificationManager = nil
    }
    
    @Test func malformedRoutingIdentityDoesNotRegister() async {
        clientProxy.pusherNotificationClientIdentifier = "invalid"
        #expect(await notificationManager.register(with: Data()) == false)
        #expect(!clientProxy.setPusherWithCalled)
    }
    
    @Test
    func whenRegistered_pusherIsCalled() async {
        _ = await notificationManager.register(with: Data())
        
        #expect(clientProxy.setPusherWithCalled)
    }
    
    @Test
    func whenRegisteredSuccess_completionSuccessIsCalled() async {
        let success = await notificationManager.register(with: Data())
        #expect(success)
    }
    
    @Test
    func whenRegisteredAndPusherThrowsError_completionFalseIsCalled() async {
        enum TestError: Error {
            case someError
        }
        
        clientProxy.setPusherWithThrowableError = TestError.someError
        let success = await notificationManager.register(with: Data())
        #expect(!success)
    }
    
    @Test
    func whenRegistered_pusherIsCalledWithCorrectValues() async throws {
        let pushkeyData = Data(1...32)
        _ = await notificationManager.register(with: pushkeyData)
        
        guard let configuration = clientProxy.setPusherWithReceivedInvocations.first else {
            Issue.record("Invalid pusher configuration sent")
            return
        }
        
        #expect(configuration.identifiers.pushkey == pushkeyData.base64EncodedString())
        #expect(configuration.identifiers.appId == appSettings.pusherAppID)
        #expect(configuration.appDisplayName == "\(InfoPlistReader.main.bundleDisplayName) (iOS)")
        #expect(configuration.deviceDisplayName == UIDevice.current.name)
        #expect(configuration.profileTag != nil)
        #expect(configuration.lang == Bundle.app.preferredLocalizations.first)
        guard case let .http(data) = configuration.kind else {
            Issue.record("Http kind expected")
            return
        }
        #expect(data.url == appSettings.pushGatewayNotifyEndpoint.absoluteString)
        #expect(data.format == .eventIdOnly)
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: nil,
                                                                      locArgs: [])),
                                         pusherNotificationClientIdentifier: clientProxy.pusherNotificationClientIdentifier)
        #expect(try data.defaultPayload == (defaultPayload.toJsonString()))
    }
    
    @Test
    func whenRegisteredAndPusherTagNotSetInSettings_tagGeneratedAndSavedInSettings() async {
        appSettings.pusherProfileTag = nil
        _ = await notificationManager.register(with: Data())
        #expect(appSettings.pusherProfileTag != nil)
    }
    
    @Test
    func whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() async {
        appSettings.pusherProfileTag = "12345"
        _ = await notificationManager.register(with: Data())
        #expect(appSettings.pusherProfileTag == "12345")
    }
    
    @Test
    func whenShowLocalNotification_notificationRequestGetsAdded() async throws {
        await notificationManager.showLocalNotification(with: "Title", subtitle: "Subtitle")
        let request = try #require(notificationCenter.addReceivedRequest)
        #expect(request.content.title == "CIVCOM")
        #expect(request.content.body == "Nowa wiadomość")
        #expect(request.content.subtitle.isEmpty)
    }
    
    @Test
    func whenStart_notificationCategoriesAreSet() {
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: L10n.actionQuickReply,
                                                        options: [])
        let messageCategory = UNNotificationCategory(identifier: NotificationConstants.Category.message,
                                                     actions: [replyAction],
                                                     intentIdentifiers: [],
                                                     options: [])
        
        let inviteCategory = UNNotificationCategory(identifier: NotificationConstants.Category.invite,
                                                    actions: [],
                                                    intentIdentifiers: [],
                                                    options: [])
        #expect(notificationCenter.setNotificationCategoriesReceivedCategories == [messageCategory, inviteCategory])
    }
    
    @Test
    func whenStart_delegateIsSet() throws {
        let delegate = try #require(notificationCenter.delegate)
        #expect(delegate.isEqual(notificationManager))
    }
    
    @Test
    func whenStart_requestAuthorizationCalledWithCorrectParams() async {
        await waitForConfirmation("requestAuthorization should be called", timeout: .seconds(10)) { confirm in
            notificationCenter.requestAuthorizationOptionsClosure = { _ in
                confirm()
                return true
            }
            notificationManager.requestAuthorization()
        }
        #expect(notificationCenter.requestAuthorizationOptionsReceivedOptions == [.alert, .sound, .badge])
    }
    
    @Test
    func whenStartAndAuthorizationGranted_delegateCalled() async {
        authorizationStatusWasGranted = false
        notificationManager.delegate = self
        await waitForConfirmation("registerForRemoteNotifications delegate function should be called", timeout: .seconds(10)) { confirm in
            registerForRemoteNotificationsDelegateCalled = {
                confirm()
            }
            notificationManager.requestAuthorization()
        }
        #expect(authorizationStatusWasGranted)
    }
    
    @Test
    func whenStartAndAuthorizedAndNotificationDisabled_registerForRemoteNotificationsNotCalled() async throws {
        appSettings.enableNotifications = false
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationManager.delegate = self
        
        notificationManager.setUserSession(UserSessionMock(.init()))
        try await Task.sleep(for: .seconds(1))
        
        #expect(!authorizationStatusWasGranted)
    }
    
    @Test
    func whenStartAndAuthorized_registerForRemoteNotificationsCalled() async {
        appSettings.enableNotifications = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationManager.delegate = self
        
        await waitForConfirmation("registerForRemoteNotifications delegate function should be called", timeout: .seconds(10)) { confirm in
            registerForRemoteNotificationsDelegateCalled = {
                confirm()
            }
            notificationManager.setUserSession(UserSessionMock(.init()))
        }
        
        #expect(authorizationStatusWasGranted)
    }
    
    @Test
    func whenWillPresentNotificationsDelegateNotSet_CorrectPresentationOptionsReturned() async throws {
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try #require(UNNotification(coder: archiver))
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [.badge, .sound, .list, .banner])
    }
    
    @Test
    func whenWillPresentNotificationsDelegateSetAndNotificationsShoudNotBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = false
        notificationManager.delegate = self
        
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [])
    }
    
    @Test
    func whenWillPresentNotificationsDelegateSetAndNotificationsShoudBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = true
        notificationManager.delegate = self
        
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [.badge, .sound, .list, .banner])
    }
    
    @Test
    func whenNotificationCenterReceivedResponseInLineReply_delegateIsCalled() async throws {
        handleInlineReplyDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: NotificationConstants.Action.inlineReply)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        #expect(handleInlineReplyDelegateCalled)
    }
    
    @Test
    func whenNotificationCenterReceivedResponseWithActionIdentifier_delegateIsCalled() async throws {
        notificationTappedDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: UNNotificationDefaultActionIdentifier)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        #expect(notificationTappedDelegateCalled)
    }
    
    @Test func canonicalTapPreservesDerivedReceiverAndRouting() async throws {
        notificationManager.delegate = self
        let userInfo: [AnyHashable: Any] = try ["pusher_notification_client_identifier": #require(clientProxy.pusherNotificationClientIdentifier),
                                                "receiver_id": "@fixture:soia.info", "room_id": "!synthetic-ios-contract", "event_id": "$synthetic-ios-contract"]
        let response = try UNTextInputNotificationResponse.with(userInfo: userInfo, actionIdentifier: UNNotificationDefaultActionIdentifier)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        let content = try #require(tappedContent)
        #expect(content.receiverID == "@fixture:soia.info")
        #expect(content.roomID == "!synthetic-ios-contract")
        #expect(content.eventID == "$synthetic-ios-contract")
        #expect(content.pusherNotificationClientIdentifier == clientProxy.pusherNotificationClientIdentifier)
    }
    
    @Test
    func updatingAppBadgeCountUsesTheClientSideCount() async {
        appSettings.roomListNotificationCountEnabled = true
        clientProxy.totalUnreadNotifications = 7
        
        await notificationManager.updateAppBadgeCount()
        
        #expect(notificationCenter.setBadgeCountReceivedNewBadgeCount == 7)
        #expect(appSettings.lastKnownBadgeCount == 7)
    }
    
    @Test
    func updatingAppBadgeCountWithoutASessionDoesNothing() async {
        appSettings.roomListNotificationCountEnabled = true
        notificationManager.setUserSession(nil)
        
        await notificationManager.updateAppBadgeCount()
        
        #expect(!notificationCenter.setBadgeCountCalled)
    }
    
    @Test
    func updatingAppBadgeCountWithFeatureDisabledDoesNothing() async {
        appSettings.roomListNotificationCountEnabled = false
        clientProxy.totalUnreadNotifications = 7
        
        await notificationManager.updateAppBadgeCount()
        
        #expect(!notificationCenter.setBadgeCountCalled)
    }
}

extension NotificationManagerTests: @MainActor NotificationManagerDelegate {
    func registerForRemoteNotifications() {
        authorizationStatusWasGranted = true
        registerForRemoteNotificationsDelegateCalled?()
    }
    
    func unregisterForRemoteNotifications() {
        authorizationStatusWasGranted = false
    }
    
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool {
        shouldDisplayInAppNotificationReturnValue
    }
    
    func notificationTapped(content: UNNotificationContent) async {
        notificationTappedDelegateCalled = true
        tappedContent = content
    }
    
    func handleInlineReply(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        handleInlineReplyDelegateCalled = true
    }
}
