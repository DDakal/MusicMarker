//
//  WatchService.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation
import SwiftUI
import WatchConnectivity

/// 워치와 iOS 간의 통신을 담당하는 서비스
///
/// 기존 WatchConnectivityManager의 기능을 WatchConnectivityManageable 프로토콜 기반으로 구현
final class WatchService: NSObject, ObservableObject, WatchConnectivityManageable, WCSessionDelegate {
    
    // MARK: - Properties
    
    private let session: WCSession = WCSession.default
    private weak var messageDelegate: WatchMessageDelegate?
    
    @Published var isConnected: Bool = false
    @Published var isReachable: Bool = false
    
    // 전역 참조를 위한 static 프로퍼티
    static var shared: WatchService?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        Self.shared = self
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            print("🎯 WatchService: WCSession 지원됨, 델리게이트 설정 중...")
            session.delegate = self
            session.activate()
            print("✅ WatchService: 세션 활성화 완료")
        } else {
            print("🚨 WatchService: WCSession이 지원되지 않는 기기")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("🎯 WatchService: 세션 활성화 완료")
        print("   - activationState: \(activationState.rawValue)")
        print("   - isPaired: \(session.isPaired)")
        print("   - isWatchAppInstalled: \(session.isWatchAppInstalled)")
        print("   - isReachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            self.isReachable = session.isReachable
            
            if self.isConnected && self.isReachable {
                print("✅ WatchService: 워치 연결 및 통신 준비 완료")
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("🎯 WatchService: Reachability 변경됨 - \(self.isReachable)")
        }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("Session watch state did change")
    }
    #endif
    
    // MARK: - Message Handling (통합)
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        guard let action = message["action"] as? String else {
            print("❌ WatchService: action 추출 실패")
            replyHandler(["success": false])
            return
        }
        
        print("🎯 WatchService: 메시지 수신 - \(action)")
        print("   - 전체 메시지: \(message)")
        print("   - session.isReachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            // 1. 먼저 delegate 방식으로 처리 시도
            let wasHandledByDelegate = self.handleMessageWithDelegate(action: action, message: message)
            
            if wasHandledByDelegate {
                print("✅ WatchService: delegate로 처리됨")
                replyHandler(["success": true])
            } else {
                // 2. 폴백: NotificationCenter 방식으로 처리
                print("🔄 WatchService: NotificationCenter로 폴백")
                self.handleMessageWithNotificationCenter(action: action, message: message)
                replyHandler(["success": true])
            }
        }
    }
    
    // MARK: - Private Message Handlers
    
    private func handleMessageWithDelegate(action: String, message: [String: Any]) -> Bool {
        print("🔍 WatchService: delegate로 메시지 처리 시도 - \(action)")
        print("   - messageDelegate 존재: \(messageDelegate != nil)")
        
        switch action {
        case "PlayToggle":
            messageDelegate?.didReceivePlayToggleCommand()
            return true
            
        case "Forward":
            messageDelegate?.didReceiveForwardCommand()
            return true
            
        case "Backward":
            messageDelegate?.didReceiveBackwardCommand()
            return true
            
        case "SendIncreasePlayback":
            messageDelegate?.didReceiveIncreaseSpeedCommand()
            return true
            
        case "SendDecreasePlayback":
            messageDelegate?.didReceiveDecreaseSpeedCommand()
            return true
            
        case "SendOriginalPlayback":
            messageDelegate?.didReceiveOriginalSpeedCommand()
            return true
            
        case "MarkerPlay":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerPlayCommand(index: index)
                return true
            }
            
        case "MarkerSave":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerSaveCommand(index: index)
                return true
            }
            
        case "MarkerDelete":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerDeleteCommand(index: index)
                return true
            }
            
            
        case "SendRequireMusicList":
            messageDelegate?.didReceiveMusicListRequestCommand()
            return true
            
        case "UUIDPlay":
            if let uuidString = message["id"] as? String, 
               let uuid = UUID(uuidString: uuidString) {
                messageDelegate?.didReceiveMusicSelectionCommand(musicID: uuid)
                return true
            }
            
        case "ChangeVolume":
            if let volume = message["volume"] as? Float {
                messageDelegate?.didReceiveVolumeChangeCommand(volume: volume)
                return true
            }
            
        default:
            print("⚠️ WatchService: 알 수 없는 액션 - \(action)")
            return false
        }
        
        return false
    }
    
    private func handleMessageWithNotificationCenter(action: String, message: [String: Any]) {
        let notificationName: Notification.Name
        var object: Any? = nil
        
        switch action {
        case "SendRequireMusicList":
            notificationName = .requireMusicList
            print("🎯 음악 목록 요청을 NotificationCenter로 전달")
            
        case "PlayToggle":
            notificationName = .plusCount
            
        case "Forward":
            notificationName = .forward
            
        case "Backward":
            notificationName = .backward
            
        case "MarkerPlay":
            notificationName = .markerPlay
            object = message["index"]
            
        case "MarkerSave":
            notificationName = .markerSave
            object = message["index"]
            
        case "SendIncreasePlayback":
            notificationName = .increaseSpeed
            
        case "SendDecreasePlayback":
            notificationName = .decreaseSpeed
            
        case "SendOriginalPlayback":
            notificationName = .originalSpeed
            
        case "UUIDPlay":
            notificationName = .UUIDPlay
            object = message["id"]
            
        case "MarkerDelete":
            notificationName = .markerDelete
            object = message["index"]
            
        case "ChangeVolume":
            notificationName = .changeVolume
            object = message["volume"]
            
        default:
            print("⚠️ 알 수 없는 액션: \(action)")
            return
        }
        
        NotificationCenter.default.post(name: notificationName, object: object)
        print("✅ NotificationCenter에 메시지 전송: \(notificationName)")
    }
    
    // MARK: - WatchConnectivityManageable Implementation
    
    func setMessageDelegate(_ delegate: WatchMessageDelegate?) {
        messageDelegate = delegate
        print("🎯 WatchService: messageDelegate 설정됨")
    }
    
    func sendPlayingState(isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval) async throws {
        print("🎯 WatchService: 재생 상태 전송 시도")
        print("   - isConnected: \(isConnected)")
        print("   - isReachable: \(isReachable)")
        print("   - session.activationState: \(session.activationState.rawValue)")
        print("   - session.isPaired: \(session.isPaired)")
        print("   - session.isWatchAppInstalled: \(session.isWatchAppInstalled)")
        
        guard session.isReachable else {
            print("🚨 WatchService: 워치에 연결할 수 없음 (isReachable: false)")
            throw DancingMarkerError.watchNotConnected
        }
        
        try await sendIsPlaying(isPlaying)
        try await sendPlayingTimes([currentTime, duration])
        print("✅ WatchService: 재생 상태 전송 성공")
    }
    
    func sendMarkers(_ markers: [TimeInterval]) async throws {
        guard session.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        let message = [
            "action": "SendMarkers",
            "markers": markers
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    func sendMusicList(_ musicList: [Music]) async throws {
        guard session.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        // 기존 포맷 유지: [[String]] 형태로 변환
        let musicTitles = musicList.map { [$0.title, $0.id.uuidString] }
        
        let message = [
            "action": "SendMusicList",
            "musicList": musicTitles
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    func sendPlaybackRate(_ rate: Float) async throws {
        guard session.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        let message = [
            "action": "SendSpeed",
            "speed": rate
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    func sendMusicTitle(_ title: String) async throws {
        guard session.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        let message = [
            "action": "SendMusicTitle",
            "musicTitle": title
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    func sendSystemVolume(_ volume: Float) async throws {
        guard session.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        let message = [
            "action": "SendSystemVolume",
            "volume": volume
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    func activateSession() async throws {
        guard WCSession.isSupported() else {
            throw DancingMarkerError.watchNotSupported
        }
        
        session.activate()
    }
    
    func deactivateSession() {
        // WCSession은 명시적 비활성화 메서드가 없음
        messageDelegate = nil
    }
    
    // MARK: - Private Helper Methods
    
    private func sendMessage(_ message: [String: Any]) async throws {
        print("�� WatchService: 메시지 전송 시도")
        
        let wcManagerSession = WCSession.default
        guard wcManagerSession.isReachable else {
            throw DancingMarkerError.watchNotConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false  // 🛡️ 간단한 플래그
            
            wcManagerSession.sendMessage(message) { replyHandler in
                guard !hasResumed else { 
                    print("⚠️ 이미 처리됨 - 무시")
                    return 
                }
                hasResumed = true
                print("✅ WatchService: 메시지 전송 성공")
                continuation.resume(returning: ())
                
            } errorHandler: { error in
                guard !hasResumed else { 
                    print("⚠️ 이미 처리됨 - 무시") 
                    return 
                }
                hasResumed = true
                print("🚨 WatchService: 메시지 전송 실패: \(error)")
                continuation.resume(throwing: DancingMarkerError.watchSendFailed)
            }
        }
    }
    
    // MARK: - Legacy Support Methods (기존 메서드명 유지)
    
    /// 기존 코드와의 호환성을 위한 메서드들
    func sendMarkersToWatch(_ markers: [TimeInterval]) {
        Task {
            try? await sendMarkers(markers)
        }
    }
    
    func sendSpeedToWatch(_ speed: Float) {
        Task {
            try? await sendPlaybackRate(speed)
        }
    }
    
    func sendIsPlayingToWatch(_ isPlaying: Bool) {
        Task {
            try? await sendIsPlaying(isPlaying)
        }
    }
    
    func sendPlayingTimesToWatch(_ playingTimes: [TimeInterval]) {
        Task {
            try? await sendPlayingTimes(playingTimes)
        }
    }
    
    func sendMusicListToWatch(_ musics: [[String]]) {
        Task {
            guard session.isReachable else { return }
            
            let message = [
                "action": "SendMusicList",
                "musicList": musics
            ] as [String : Any]
            
            try? await sendMessage(message)
        }
    }
    
    func sendTitleToWatch(_ musicTitle: String) {
        Task {
            try? await sendMusicTitle(musicTitle)
        }
    }
    
    func sendSystemVolumeToWatch(_ volume: Float) {
        Task {
            try? await sendSystemVolume(volume)
        }
    }
    
    // MARK: - Private Async Helper Methods
    
    private func sendIsPlaying(_ isPlaying: Bool) async throws {
        let message = [
            "action": "SendIsPlaying",
            "isPlaying": isPlaying
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    private func sendPlayingTimes(_ playingTimes: [TimeInterval]) async throws {
        let message = [
            "action": "SendPlayingTimes",
            "playingTimes": playingTimes
        ] as [String : Any]
        
        try await sendMessage(message)
    }
    
    // 메시지 처리를 위한 공개 메서드 추가
    func handleReceivedWatchMessage(action: String, message: [String: Any]) -> Bool {
        switch action {
        case "PlayToggle":
            messageDelegate?.didReceivePlayToggleCommand()
            return true
            
        case "Forward":
            messageDelegate?.didReceiveForwardCommand()
            return true
            
        case "Backward":
            messageDelegate?.didReceiveBackwardCommand()
            return true
            
        case "SendIncreasePlayback":
            messageDelegate?.didReceiveIncreaseSpeedCommand()
            return true
            
        case "SendDecreasePlayback":
            messageDelegate?.didReceiveDecreaseSpeedCommand()
            return true
            
        case "SendOriginalPlayback":
            messageDelegate?.didReceiveOriginalSpeedCommand()
            return true
            
        case "MarkerPlay":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerPlayCommand(index: index)
                return true
            }
            
        case "MarkerSave":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerSaveCommand(index: index)
                return true
            }
            
        case "UUIDPlay":
            if let uuidString = message["id"] as? String, 
               let uuid = UUID(uuidString: uuidString) {
                messageDelegate?.didReceiveMusicSelectionCommand(musicID: uuid)
                return true
            }
            
        case "MarkerDelete":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerDeleteCommand(index: index)
                return true
            }
            
            
        case "SendRequireMusicList":
            messageDelegate?.didReceiveMusicListRequestCommand()
            return true
            
        case "ChangeVolume":
            if let volume = message["volume"] as? Float {
                messageDelegate?.didReceiveVolumeChangeCommand(volume: volume)
                return true
            }
            
        default:
            return false
        }
        
        return false
    }
}
