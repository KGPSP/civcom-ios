// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import AnalyticsEvents

struct CIVCOMDisabledAnalyticsClient: AnalyticsClientProtocol {
    var isRunning: Bool {
        false
    }
    
    func start(analyticsConfiguration: AnalyticsConfiguration) { }
    func reset() { }
    func stop() { }
    func capture(_ event: AnalyticsEventProtocol) { }
    func screen(_ event: AnalyticsScreenProtocol) { }
    func updateUserProperties(_ event: AnalyticsEvent.UserProperties) { }
}
