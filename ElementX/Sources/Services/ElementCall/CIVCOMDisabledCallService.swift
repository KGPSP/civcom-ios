// Copyright 2026 KG PSP.
// SPDX-License-Identifier: AGPL-3.0-only
import Combine
import ElementCall

final class CIVCOMDisabledCallService: ElementCallServiceProtocol {
    var actions: AnyPublisher<ElementCallServiceAction, Never> {
        Empty().eraseToAnyPublisher()
    }
    
    let ongoingCallRoomIDPublisher = CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher()
    var nativeCallController: ElementCallController? {
        nil
    }
    
    func setUserSession(_ userSession: UserSessionProtocol?) { }
    func handleNativeCallRequest(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool) -> Bool {
        true
    }
    
    func minimizeNativeCall() { }
    func restoreNativeCall() { }
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool) async { }
    func reportCallSessionConnected(roomID: String) { }
    func tearDownCallSession(roomID: String) { }
    func setAudioEnabled(_ enabled: Bool, roomID: String) { }
}
