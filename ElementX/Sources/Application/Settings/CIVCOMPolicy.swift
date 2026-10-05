// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only

import Foundation

nonisolated enum CIVCOMProviderError: Error { case notAllowed }

nonisolated enum CIVCOMPolicy {
    static let callsEnabled = false
    static let mapsEnabled = false
    static let genericNotifications = true
    static let developerOptionsEnabled = false
    
    static func allowsAccountProvider(_ value: String) -> Bool {
        if value == "soia.info" {
            return true
        }
        guard let url = URL(string: value) else { return false }
        return isHTTPSOrigin(url, host: "matrix.soia.info") && ["", "/"].contains(url.path) && url.query == nil && url.fragment == nil
    }
    
    static func isNotificationClientIdentifier(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { "0123456789abcdef".contains($0) }
    }
    
    static func notificationCredentialIndex(for identifier: String?, available: [String?]) -> Int? {
        guard let identifier, isNotificationClientIdentifier(identifier) else { return nil }
        return available.firstIndex { $0 == identifier }
    }
    
    static func allowsStoredAccount(userID: String, homeserverURL: String) -> Bool {
        guard let url = URL(string: homeserverURL), isHTTPSOrigin(url, host: "matrix.soia.info"),
              ["", "/"].contains(url.path), url.query == nil, url.fragment == nil else { return false }
        return userID.range(of: "^@[a-z0-9._=/-]+:soia[.]info$", options: .regularExpression) != nil
    }
    
    static func isRoomEventIdentifier(_ value: String, prefix: Character) -> Bool {
        value.first == prefix && (2...255).contains(value.utf8.count) && !value.unicodeScalars.contains {
            CharacterSet.whitespacesAndNewlines.contains($0) || CharacterSet.controlCharacters.contains($0)
        }
    }
    
    static func authenticationAPI(for provider: String) throws -> URL {
        guard allowsAccountProvider(provider) else { throw CIVCOMProviderError.notAllowed }
        return URL(string: "https://matrix.soia.info")!
    }
    
    static func isHTTPSOrigin(_ url: URL, host: String) -> Bool {
        url.scheme == "https" && url.host == host && (url.port == nil || url.port == 443) && url.user == nil && url.password == nil
    }
    
    static func isCallback(_ url: URL, for redirectURL: URL) -> Bool {
        isHTTPSOrigin(url, host: "civcom.soia.info") && url.path == redirectURL.path && url.fragment == nil
    }
}

#if canImport(UserNotifications)
import UserNotifications

nonisolated extension CIVCOMPolicy {
    static func redact(_ content: UNMutableNotificationContent) {
        content.title = "CIVCOM"
        content.subtitle = ""
        content.body = "Nowa wiadomość"
        content.attachments = []
        content.categoryIdentifier = ""
    }
}
#endif
