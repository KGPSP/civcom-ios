//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@preconcurrency import UserNotifications

final nonisolated class NotificationServiceExtension: UNNotificationServiceExtension {
    private let keychainController = KeychainController(service: .sessions, accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping @Sendable (UNNotificationContent) -> Void) {
        let credentials = keychainController.restorationTokens()
        contentHandler(CIVCOMLocalNotificationRouting.content(for: request.content, activeCredentials: credentials))
    }
}

nonisolated enum CIVCOMLocalNotificationRouting {
    static func content(for incoming: UNNotificationContent, activeCredentials: [KeychainCredentials]) -> UNNotificationContent {
        guard let content = incoming.mutableCopy() as? UNMutableNotificationContent else { return incoming }
        CIVCOMPolicy.redact(content)
        content.receiverID = nil
        guard let roomID = content.roomID, CIVCOMPolicy.isRoomEventIdentifier(roomID, prefix: "!"),
              let eventID = content.eventID, CIVCOMPolicy.isRoomEventIdentifier(eventID, prefix: "$"),
              let index = CIVCOMPolicy.notificationCredentialIndex(for: content.pusherNotificationClientIdentifier,
                                                                   available: activeCredentials.map(\.restorationToken.pusherNotificationClientIdentifier)) else { return content }
        let credentials = activeCredentials[index]
        let session = credentials.restorationToken.session
        guard credentials.userID == session.userId,
              CIVCOMPolicy.allowsStoredAccount(userID: credentials.userID, homeserverURL: session.homeserverUrl) else { return content }
        content.receiverID = credentials.userID
        return content
    }
}
