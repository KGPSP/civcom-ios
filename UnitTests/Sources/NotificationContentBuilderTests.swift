//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Dynamic
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing
import UserNotifications

nonisolated struct NotificationContentBuilderTests {
    var notificationContentBuilder: NotificationContentBuilder
    var mediaProvider: MediaProviderMock
    var notificationContent: UNMutableNotificationContent
    
    init() async {
        notificationContent = .init()
        let stringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                          style: .plain)
        mediaProvider = MediaProviderMock(.init())
        notificationContentBuilder = await NotificationContentBuilder(messageEventStringBuilder: stringBuilder,
                                                                      notificationSoundName: UNNotificationSoundName("message.caf"),
                                                                      userSession: NSEUserSessionMock(.init()))
    }
    
    @Test
    mutating func dmMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        // Checking if nil without using asObject always fails
        #expect(communicationContext.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:soia.info!test:soia.info")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        // Checking if nil without using asObject always fails
        #expect(communicationContext.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:soia.info!test:soia.info")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: false,
                                                               threadRootEventID: "thread"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:soia.info!test:soia.infothread")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func dmMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:soia.info!test:soia.infothread")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotification() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound == nil)
        // Remember we remove the @ due to an iOS bug
        #expect(notificationContent.threadIdentifier == "bob:soia.info!testroom:soia.info")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotificationWithMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID == nil)
        #expect(notificationContent.sound != nil)
        #expect(notificationContent.threadIdentifier == "bob:soia.info!testroom:soia.info")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func roomMessageNotificationWithThread() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: false,
                                                               threadRootEventID: "thread123"))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound == nil)
        #expect(notificationContent.threadIdentifier == "bob:soia.info!testroom:soia.infothread123")
        #expect(notificationContent.attachments == [])
    }
    
    @Test
    mutating func liveLocationStartNotification() async {
        let event = TimelineEventSDKMock()
        event.eventIdReturnValue = UUID().uuidString
        event.contentReturnValue = .state(content: .beaconInfo)
        
        let notificationItem = NotificationItemProxyMock(.init(event: .timeline(event: event),
                                                               roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.sound != nil)
    }
    
    @Test
    mutating func otherStateEventNotification() async {
        let event = TimelineEventSDKMock()
        event.eventIdReturnValue = UUID().uuidString
        event.contentReturnValue = .state(content: .roomName)
        
        let notificationItem = NotificationItemProxyMock(.init(event: .timeline(event: event),
                                                               roomID: "!test:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "Alice",
                                                               roomJoinedMembers: 2,
                                                               isRoomDirect: true,
                                                               isRoomPrivate: true,
                                                               isNoisy: true))
        
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
    }
    
    @Test
    mutating func roomMessageNotificationWithThreadAndMention() async {
        let notificationItem = NotificationItemProxyMock(.init(roomID: "!testroom:soia.info",
                                                               receiverID: "@bob:soia.info",
                                                               senderDisplayName: "Alice",
                                                               roomDisplayName: "General",
                                                               roomJoinedMembers: 5,
                                                               isRoomDirect: false,
                                                               isRoomPrivate: false,
                                                               isNoisy: true,
                                                               hasMention: true,
                                                               threadRootEventID: "thread123"))
        await notificationContentBuilder.process(notificationContent: &notificationContent,
                                                 notificationItem: notificationItem,
                                                 mediaProvider: mediaProvider)
        let communicationContext = Dynamic(notificationContent, memberName: "communicationContext")
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(communicationContext.sender.displayName.asObject == nil)
        #expect(notificationContent.body == "Nowa wiadomość")
        #expect(notificationContent.title == "CIVCOM")
        #expect(notificationContent.subtitle.isEmpty)
        #expect(notificationContent.categoryIdentifier.isEmpty)
        #expect(notificationContent.threadRootEventID != nil)
        #expect(notificationContent.sound != nil)
        #expect(notificationContent.threadIdentifier == "bob:soia.info!testroom:soia.infothread123")
        #expect(notificationContent.attachments == [])
    }
}
