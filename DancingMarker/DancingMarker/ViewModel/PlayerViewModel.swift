//
//  PlayerViewModel.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import SwiftUI
import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// 새로운 아키텍처 기반 플레이어 뷰모델
///
/// 4개의 핵심 서비스를 조합하여 음악 재생 기능을 제공합니다:
/// - AudioService: 오디오 재생 관리
/// - MarkerService: 마커 관리
/// - WatchService: 워치 연동
/// - LiveActivityService: Control Center/Lock Screen 관리
@MainActor
final class PlayerViewModel: ObservableObject {
    
    // MARK: - Services
    
    internal let audioService: any AudioPlayable
    internal let markerService: any MarkerManageable
    internal let watchService: any WatchConnectivityManageable
    internal let liveActivityService: any ControlCenterManageable
    
    // MARK: - Published Properties
    
    @Published var currentMusic: MusicData?
    @Published var musicList: [MusicData] = []
    
    // 오디오 재생 상태
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var playbackRate: Float = 1.0
    @Published var volume: Float = 1.0
    @Published var isDragging: Bool = false
    
    // UI 관련
    @Published var progress: Double = 0.0
    @Published var formattedProgress: String = "0:00"
    @Published var formattedDuration: String = "0:00"
    
    // 마커 관련
    @Published var markers: [TimeInterval] = [-1, -1, -1]
    @Published var isEditingMarker: Bool = false
    @Published var editingMarkerIndex: Int?
    
    // 기타
    @Published var countNum: Int = 0
    
    // MARK: - Internal Properties
    
    internal let formatter: DateComponentsFormatter
    internal var cancellables = Set<AnyCancellable>()
    
    /// Timer는 thread-safe하므로 nonisolated context에서도 안전하게 접근 가능
    nonisolated(unsafe) internal var timer: Timer?
    
    // MARK: - Initialization
    
    init(
        audioService: any AudioPlayable,
        markerService: any MarkerManageable,
        watchService: any WatchConnectivityManageable,
        liveActivityService: any ControlCenterManageable
    ) {
        self.audioService = audioService
        self.markerService = markerService
        self.watchService = watchService
        self.liveActivityService = liveActivityService
        
        // DateComponentsFormatter 설정
        self.formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        
        // 초기화 작업
        setupServiceObservation()
        setupWatchNotifications()
        setupRemoteControlHandlers()
    }
    
    deinit {
        // nonisolated 메서드들로 정리 작업
        stopTimerSync()
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

// MARK: - Setup Methods

extension PlayerViewModel {
    
    internal func setupServiceObservation() {
        // AudioService 상태 관찰 설정
        // TODO: 각 서비스의 Publisher들이 구현되면 연결
        
        // 임시로 기본 설정
        formattedProgress = "0:00"
        formattedDuration = "0:00"
    }
    
    internal func setupWatchNotifications() {
        // 워치 관련 NotificationCenter 설정
        // 기존 PlayerModel의 notification 로직을 async/await 방식으로 변경
        // Notification.Name들은 Manager/WCManager.swift에서 이미 정의됨
        
        NotificationCenter.default.addObserver(
            forName: .plusCount,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handlePlayToggle()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .forward,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleForward5Seconds()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .backward,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleBackward5Seconds()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerPlay,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int {
                Task { @MainActor in
                    await self?.handleMarkerPlay(at: index)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int {
                Task { @MainActor in
                    await self?.handleMarkerSave(at: index)
                }
            }
        }
        
        // 추가 알림들 TODO: 다른 extension에서 구현
    }
    
    internal func setupRemoteControlHandlers() {
        // Control Center 리모트 컨트롤 설정
        // TODO: PlayerViewModel+RemoteControl.swift에서 구체적으로 구현
    }
}

// MARK: - Helper Methods

extension PlayerViewModel {
    
    internal func updateProgress() {
        guard duration > 0 else {
            progress = 0
            return
        }
        progress = currentTime / duration
    }
    
    internal func updateFormattedTime() {
        formattedProgress = formattedTime(currentTime)
    }
    
    internal func formattedTime(_ time: TimeInterval) -> String {
        return formatter.string(from: time) ?? "0:00"
    }
}

// MARK: - Timer Management

extension PlayerViewModel {
    
    /// MainActor 컨텍스트에서 타이머를 중지합니다
    internal func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// deinit에서 사용할 수 있는 동기적 타이머 중지 메서드
    nonisolated internal func stopTimerSync() {
        // Timer는 thread-safe하므로 안전하게 정리 가능
        timer?.invalidate()
        timer = nil
    }
    
    /// 타이머를 시작합니다 (타이머 관련 기능이 구현될 때까지 임시)
    internal func startTimer() {
        // TODO: PlayerViewModel+Timer.swift에서 구현
        print("TODO: startTimer 구현 필요")
    }
}

// MARK: - Placeholder Methods for Extensions

extension PlayerViewModel {
    
    // TODO: PlayerViewModel+Marker.swift에서 구현
    internal func handleMarkerPlay(at index: Int) async {
        print("TODO: handleMarkerPlay 구현 필요")
    }
    
    internal func handleMarkerSave(at index: Int) async {
        print("TODO: handleMarkerSave 구현 필요")
    }
    
    // TODO: PlayerViewModel+Watch.swift에서 구현
    internal func sendMusicListToWatch() async {
        print("TODO: sendMusicListToWatch 구현 필요")
    }
}
