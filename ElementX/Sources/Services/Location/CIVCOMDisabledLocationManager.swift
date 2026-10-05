// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import Combine
import CoreLocation

final class CIVCOMDisabledLocationManager: LiveLocationManagerProtocol {
    let authorizationStatus = CurrentValueSubject<CLAuthorizationStatus, Never>(.denied).asCurrentValuePublisher()
    func requestAlwaysAuthorizationIfPossible() -> Bool {
        false
    }
    
    func startLiveLocation(roomID: String, duration: Duration) async -> Result<Void, LiveLocationManagerError> {
        .failure(.startFailed)
    }
    
    func stopLiveLocation(roomID: String) async { }
}
