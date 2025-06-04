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
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WatchConnectivityManageable Implementation
    
    func sendPlayingState(isPlaying: Bool, currentTime: TimeInterval, duration: TimeInterval) async throws {
        try await sendIsPlaying(isPlaying)
        try await sendPlayingTimes([currentTime, duration])
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
        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message) { replyHandler in
                continuation.resume()
            } errorHandler: { error in
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
        print("ACTIVATED ON iOS")
        #elseif os(watchOS)
        print("ACTIVATED ON watchOS")
        #endif
        
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.isConnected = activationState == .activated
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("Reachability changed: \(self.isReachable)")
            
            if !self.isReachable {
                print("Session is not reachable, attempting to reactivate...")
                self.session.activate()
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
