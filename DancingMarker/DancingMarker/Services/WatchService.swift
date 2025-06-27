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
final class WatchService: NSObject, WatchConnectivityManageable {
    
    // MARK: - Published Properties
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isReachable: Bool = false
    
    // MARK: - Private Properties
    
    private let session: WCSession = WCSession.default
    private weak var messageDelegate: WatchMessageDelegate?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            print("🎯 WatchService: WCSession 지원됨, 델리게이트 설정 중...")
            session.delegate = self
            session.activate()
            print("🎯 WatchService: WCSession 활성화 요청 완료")
        } else {
            print("🚨 WatchService: WCSession이 지원되지 않는 기기")
        }
    }
    
    // MARK: - WatchConnectivityManageable Implementation
    
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
    
    func setMessageDelegate(_ delegate: WatchMessageDelegate?) {
        messageDelegate = delegate
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
        print("🎯 WatchService: 메시지 전송 시도")
        print("   - 메시지 액션: \(message["action"] ?? "Unknown")")
        print("   - isReachable: \(session.isReachable)")
        
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message) { replyHandler in
                print("✅ WatchService: 메시지 전송 성공, 응답: \(replyHandler)")
                continuation.resume()
            } errorHandler: { error in
                print("🚨 WatchService: 메시지 전송 실패")
                print("   - 원본 에러: \(error.localizedDescription)")
                print("   - 에러 코드: \(error._code)")
                print("   - 에러 도메인: \(error._domain)")
                
                // 더 구체적인 에러 정보 제공
                if error._code == 7012 {
                    print("   - 워치 앱이 실행되지 않았거나 백그라운드 상태")
                } else if error._code == 7013 {
                    print("   - 워치가 연결되지 않음")
                }
                
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
}

// MARK: - WCSessionDelegate

extension WatchService: WCSessionDelegate {
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        #if os(iOS)
        print("🎯 WatchService: iOS에서 세션 활성화 완료")
        #elseif os(watchOS)
        print("🎯 WatchService: watchOS에서 세션 활성화 완료")
        #endif
        
        print("   - activationState: \(activationState.rawValue)")
        print("   - isPaired: \(session.isPaired)")
        print("   - isWatchAppInstalled: \(session.isWatchAppInstalled)")
        print("   - isReachable: \(session.isReachable)")
        
        if let error = error {
            print("🚨 WatchService: 세션 활성화 중 오류 발생: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.isConnected = activationState == .activated
            
            if self.isConnected && self.isReachable {
                print("✅ WatchService: 워치 연결 및 통신 준비 완료")
            } else if self.isConnected && !self.isReachable {
                print("⚠️ WatchService: 워치가 연결되었지만 통신할 수 없음 (워치가 꺼져있거나 범위 밖)")
            } else {
                print("🚨 WatchService: 워치 연결 실패")
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            let wasReachable = self.isReachable
            self.isReachable = session.isReachable
            
            print("🎯 WatchService: Reachability 변경됨")
            print("   - 이전 상태: \(wasReachable)")
            print("   - 현재 상태: \(self.isReachable)")
            print("   - isPaired: \(session.isPaired)")
            print("   - isWatchAppInstalled: \(session.isWatchAppInstalled)")
            print("   - activationState: \(session.activationState.rawValue)")
            
            if !self.isReachable {
                print("🚨 WatchService: 세션이 연결되지 않음, 재활성화 시도...")
                self.session.activate()
            } else {
                print("✅ WatchService: 워치 연결 복원됨")
            }
        }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive: \(session.activationState.rawValue)")
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("Session watch state did change: \(session.activationState.rawValue)")
    }
    #endif
    
    // MARK: - Message Handling
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        
        guard let action = message["action"] as? String else {
            replyHandler(["success": false])
            return
        }
        
        DispatchQueue.main.async {
            self.handleReceivedMessage(action: action, message: message)
            replyHandler(["success": true])
        }
    }
    
    private func handleReceivedMessage(action: String, message: [String: Any]) {
        switch action {
        case "PlayToggle":
            messageDelegate?.didReceivePlayToggleCommand()
            
        case "Forward":
            messageDelegate?.didReceiveForwardCommand()
            
        case "Backward":
            messageDelegate?.didReceiveBackwardCommand()
            
        case "SendIncreasePlayback":
            messageDelegate?.didReceiveIncreaseSpeedCommand()
            
        case "SendDecreasePlayback":
            messageDelegate?.didReceiveDecreaseSpeedCommand()
            
        case "SendOriginalPlayback":
            messageDelegate?.didReceiveOriginalSpeedCommand()
            
        case "MarkerPlay":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerPlayCommand(index: index)
            }
            
        case "MarkerSave":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerSaveCommand(index: index)
            }
            
        case "MarkerDelete":
            if let index = message["index"] as? Int {
                messageDelegate?.didReceiveMarkerDeleteCommand(index: index)
            }
            
        case "MarkerEdit":
            if let forEdit = message["forEdit"] as? [Int], forEdit.count >= 2 {
                messageDelegate?.didReceiveMarkerEditCommand(index: forEdit[0], adjustment: Double(forEdit[1]))
            }
            
        case "MarkerEditSuccess":
            if let forEdit = message["forEdit"] as? [Int], forEdit.count >= 2 {
                messageDelegate?.didReceiveMarkerEditSuccessCommand(index: forEdit[0], newTime: Double(forEdit[1]))
            }
            
        case "UUIDPlay":
            if let uuidString = message["id"] as? String, let uuid = UUID(uuidString: uuidString) {
                messageDelegate?.didReceiveMusicSelectionCommand(musicID: uuid)
            }
            
        case "ChangeVolume":
            if let volume = message["volume"] as? Float {
                messageDelegate?.didReceiveVolumeChangeCommand(volume: volume)
            }
            
        case "SendRequireMusicList":
            messageDelegate?.didReceiveMusicListRequestCommand()
            
        default:
            print("Unknown action received: \(action)")
        }
    }
}
