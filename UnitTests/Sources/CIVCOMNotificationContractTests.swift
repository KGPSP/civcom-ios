// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import Combine
@testable import ElementX
import MatrixRustSDK
import SwiftUI
import Testing
import UserNotifications

struct CIVCOMNotificationContractTests {
    let clientID = "48df8697ad56e8c97b385a49463b1674db8c60a358d08c1241eb06329f46d855"
    
    @Test func canonicalGatewayMetadataSelectsSessionAndBuilderDerivesReceiver() async throws {
        let push: [AnyHashable: Any] = ["pusher_notification_client_identifier": clientID, "room_id": "!synthetic-ios-contract", "event_id": "$synthetic-ios-contract",
                                        "aps": ["mutable-content": 1, "alert": ["title": "CIVCOM", "body": "Nowa wiadomość"]]]
        let content = UNMutableNotificationContent()
        content.userInfo = push
        #expect(try CIVCOMPolicy.isNotificationClientIdentifier(#require(content.pusherNotificationClientIdentifier)))
        #expect(content.receiverID == nil)
        let available = [String(repeating: "a", count: 64), clientID]
        #expect(CIVCOMPolicy.notificationCredentialIndex(for: content.pusherNotificationClientIdentifier, available: available) == 1)
        let item = NotificationItemProxyMock(.init(roomID: "!synthetic-ios-contract", receiverID: "@fixture:soia.info", senderDisplayName: "SECRET SENDER", roomDisplayName: "SECRET ROOM", isNoisy: true))
        let eventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()), style: .plain)
        let builder = NotificationContentBuilder(messageEventStringBuilder: eventStringBuilder, notificationSoundName: UNNotificationSoundName("message.caf"), userSession: NSEUserSessionMock(.init()))
        var result = content
        await builder.process(notificationContent: &result, notificationItem: item, mediaProvider: MediaProviderMock(.init()))
        #expect(result.receiverID == "@fixture:soia.info")
        #expect(result.roomID == "!synthetic-ios-contract")
        #expect(result.pusherNotificationClientIdentifier == clientID)
        #expect(result.title == "CIVCOM" && result.body == "Nowa wiadomość" && result.subtitle.isEmpty)
        #expect(result.attachments.isEmpty)
    }
    
    @Test func localNSEDoesNotTrustRemoteReceiverOrForeignCredentials() {
        let incoming = UNMutableNotificationContent()
        incoming.userInfo = ["pusher_notification_client_identifier": clientID, "receiver_id": "@spoof:elsewhere", "room_id": "!room:soia.info", "event_id": "$event"]
        let session = MatrixRustSDK.Session(accessToken: "synthetic", refreshToken: nil, userId: "@fixture:soia.info", deviceId: "DEVICE",
                                            homeserverUrl: "https://matrix.soia.info", oauthData: "{\"client_id\":\"synthetic\"}", slidingSyncVersion: .native)
        let token = RestorationToken(session: session, sessionDirectories: .init(), passphrase: "synthetic", pusherNotificationClientIdentifier: clientID)
        let result = CIVCOMLocalNotificationRouting.content(for: incoming, activeCredentials: [.init(userID: session.userId, restorationToken: token)])
        #expect(result.receiverID == session.userId)
        #expect(result.body == "Nowa wiadomość" && result.categoryIdentifier.isEmpty && result.attachments.isEmpty)
        #expect(result.roomID == "!room:soia.info" && result.eventID == "$event")
        #expect(CIVCOMLocalNotificationRouting.content(for: incoming, activeCredentials: []).receiverID == nil)
        let foreign = RestorationToken(session: session, sessionDirectories: .init(), passphrase: "synthetic", pusherNotificationClientIdentifier: clientID)
        #expect(CIVCOMLocalNotificationRouting.content(for: incoming, activeCredentials: [.init(userID: "@foreign:matrix.org", restorationToken: foreign)]).receiverID == nil)
    }
    
    @Test func malformedRoomEventIdentifiersAreNotEligibleForRouting() {
        for value in ["!", "!bad name", "!bad\nname", "wrong", "!" + String(repeating: "a", count: 255)] {
            #expect(!CIVCOMPolicy.isRoomEventIdentifier(value, prefix: "!"))
        }
        #expect(!CIVCOMPolicy.isRoomEventIdentifier("$bad\nname", prefix: "$"))
        #expect(CIVCOMPolicy.isRoomEventIdentifier("!room:soia.info", prefix: "!"))
        #expect(CIVCOMPolicy.isRoomEventIdentifier("$synthetic-ios-contract", prefix: "$"))
    }
    
    @Test func missingWrongTypeAndMixedClientIDsCannotMatch() {
        let content = UNMutableNotificationContent()
        #expect(content.pusherNotificationClientIdentifier == nil)
        #expect(CIVCOMPolicy.notificationCredentialIndex(for: content.pusherNotificationClientIdentifier, available: [clientID]) == nil)
        content.userInfo = ["pusher_notification_client_identifier": 5]
        #expect(content.pusherNotificationClientIdentifier == nil)
        for value in ["test-client", String(repeating: "A", count: 64), String(repeating: "f", count: 63)] {
            #expect(!CIVCOMPolicy.isNotificationClientIdentifier(value))
        }
        #expect(CIVCOMPolicy.notificationCredentialIndex(for: clientID, available: [String(repeating: "a", count: 64)]) == nil)
        #expect(CIVCOMPolicy.notificationCredentialIndex(for: "invalid", available: ["invalid"]) == nil)
    }
}
