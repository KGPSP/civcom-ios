// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

nonisolated enum CIVCOMOAuthPolicy {
    static let issuer = "https://auth.soia.info/"
    enum Failure: Error { case untrustedMetadata }
    
    static func validateMetadata(_ data: Data) throws -> String {
        guard data.count <= 65536,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["issuer"] as? String == issuer else { throw Failure.untrustedMetadata }
        for key in ["authorization_endpoint", "token_endpoint", "registration_endpoint", "jwks_uri"] {
            guard let value = object[key] as? String, let url = URL(string: value),
                  CIVCOMPolicy.isHTTPSOrigin(url, host: "auth.soia.info") else { throw Failure.untrustedMetadata }
        }
        return issuer
    }
}

nonisolated protocol CIVCOMOAuthMetadataProvider: Sendable {
    func verifiedIssuer() async throws -> String
}

nonisolated struct CIVCOMOwnedOAuthMetadataProvider: CIVCOMOAuthMetadataProvider {
    func verifiedIssuer() async throws -> String {
        let endpoint: URL = "https://matrix.soia.info/_matrix/client/v1/auth_metadata"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration, delegate: CIVCOMNoRedirectDelegate(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("\(InfoPlistReader.app.bundleDisplayName)/\(InfoPlistReader.app.bundleShortVersionString) (iOS)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200, response.url == endpoint else {
            throw CIVCOMOAuthPolicy.Failure.untrustedMetadata
        }
        return try CIVCOMOAuthPolicy.validateMetadata(data)
    }
}

final nonisolated class CIVCOMNoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
