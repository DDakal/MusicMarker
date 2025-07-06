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
import SwiftData

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
    internal let modelContext: ModelContext
    
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
    @Published var isControlCenterSeeking: Bool = false
    
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
    internal var lastSeekTask: Task<Void, Never>?
    
    /// Timer는 thread-safe하므로 nonisolated context에서도 안전하게 접근 가능
    nonisolated(unsafe) internal var timer: Timer?
    
    // private을 internal로 변경
    internal var isMarkerSeeking: Bool = false
    
    // MARK: - Initialization
    
    init(
        audioService: any AudioPlayable,
        markerService: any MarkerManageable,
        watchService: any WatchConnectivityManageable,
        liveActivityService: any ControlCenterManageable,
        modelContext: ModelContext
    ) {
        self.audioService = audioService
        self.markerService = markerService
        self.watchService = watchService
        self.liveActivityService = liveActivityService
        self.modelContext = modelContext
        
        // DateComponentsFormatter 설정
        self.formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        
        // 초기화 작업
        setupServiceObservation()
        
        // WatchService 델리게이트 설정
        self.watchService.setMessageDelegate(self)
        print("WatchService 델리게이트 설정 완료")
    }
    
    deinit {
        // Timer 정리 - nonisolated context에서 안전하게 처리
        timer?.invalidate()
        timer = nil
        
        // NotificationCenter 정리
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

// MARK: - Setup Methods

extension PlayerViewModel {
    
    internal func setupServiceObservation() {
        // 기본 설정
        formattedProgress = "0:00"
        formattedDuration = "0:00"
        
        // AudioService 직접 구독 설정 (타이머 대체)
        setupAudioServiceSubscription()
        
        // WatchService 델리게이트 설정
        watchService.setMessageDelegate(self)
        print("WatchService 델리게이트 설정 완료")
        
        // WatchService 세션 활성화
        Task { @MainActor in
            do {
                try await watchService.activateSession()
                print("🎯 WatchService 세션 활성화 완료")
                
                // 워치 알림 설정
                setupWatchNotifications()
                print("🎯 워치 알림 설정 완료")
                
            } catch {
                print("❌ WatchService 세션 활성화 실패: \(error)")
            }
        }
    }
}

// MARK: - Helper Methods

extension PlayerViewModel {
    
    internal func setupControlCenter() {
        Task {
            do {
                try await liveActivityService.setupRemoteControlHandlers(self)
                print("✅ Control Center 핸들러 설정 완료")
            } catch {
                print("❌ Control Center 핸들러 설정 실패: \(error)")
            }
        }
    }
    
    public func updateProgress() {
        guard duration > 0 else {
            progress = 0
            return
        }
        progress = currentTime / duration
    }
    
    public func updateFormattedTime() {
        formattedProgress = formattedTime(currentTime)
    }
    
    public func formattedTime(_ time: TimeInterval) -> String {
        return formatter.string(from: time) ?? "0:00"
    }
}

// MARK: - Placeholder Methods for Extensions

extension PlayerViewModel {
    
    // 모든 handler 메서드들은 각각의 extension에서 구현됨:
    // - PlayerViewModel+Audio.swift: handlePlayToggle, handleForward5Seconds, handleBackward5Seconds
    // - PlayerViewModel+Marker.swift: handleMarkerPlay, handleMarkerSave, handleMarkerDelete
    // - PlayerViewModel+Watch.swift: 기타 워치 관련 handler들
    // - PlayerViewModel+LiveActivity.swift: RemoteControlHandler
}

// MARK: - Computed Properties for Service Access

extension PlayerViewModel {
    
    /// MarkerService 인스턴스에 직접 접근할 수 있도록 하는 computed property
    /// PlayingView에서 편집 중인 마커에 직접 접근할 때 사용됩니다
    var markerServiceInstance: (any MarkerManageable)? {
        return markerService
    }
}

// MARK: - WatchMessageDelegate Implementation

extension PlayerViewModel: WatchMessageDelegate {
    
    func didReceivePlayToggleCommand() {
        Task { @MainActor in
            await handlePlayToggle()
        }
    }
    
    func didReceiveForwardCommand() {
        Task { @MainActor in
            await handleForward5Seconds()
        }
    }
    
    func didReceiveBackwardCommand() {
        Task { @MainActor in
            await handleBackward5Seconds()
        }
    }
    
    func didReceiveIncreaseSpeedCommand() {
        Task { @MainActor in
            await handleIncreaseSpeed()
        }
    }
    
    func didReceiveDecreaseSpeedCommand() {
        Task { @MainActor in
            await handleDecreaseSpeed()
        }
    }
    
    func didReceiveOriginalSpeedCommand() {
        Task { @MainActor in
            await handleOriginalSpeed()
        }
    }
    
    func didReceiveMarkerPlayCommand(index: Int) {
        Task { @MainActor in
            await handleMarkerPlay(at: index)
        }
    }
    
    func didReceiveMarkerSaveCommand(index: Int) {
        Task { @MainActor in
            await handleMarkerSave(at: index)
        }
    }
    
    func didReceiveMarkerDeleteCommand(index: Int) {
        Task { @MainActor in
            await handleMarkerDelete(at: index)
        }
    }
    
    func didReceiveMarkerEditCommand(index: Int, adjustment: Double) {
        Task { @MainActor in
            await handleMarkerEdit(at: index, adjustment: adjustment)
        }
    }
    
    func didReceiveMarkerEditSuccessCommand(index: Int, newTime: Double) {
        Task { @MainActor in
            await handleMarkerEditSuccess(at: index, newTime: newTime)
        }
    }
    
    func didReceiveMusicSelectionCommand(musicID: UUID) {
        Task { @MainActor in
            await handleMusicSelection(musicID: musicID)
        }
    }
    
    func didReceiveVolumeChangeCommand(volume: Float) {
        Task { @MainActor in
            await handleVolumeChange(volume: volume)
        }
    }
    
    func didReceiveMusicListRequestCommand() {
        Task { @MainActor in
            await handleMusicListRequest()
        }
    }
}

/// Control Center에서 다음 트랙 명령 (이 앱에서는 지원하지 않음)
nonisolated func handleNextTrackCommand() {
    print("⏭️ handleNextTrackCommand 호출됨!")
    
    Task { @MainActor in
        print("Control Center에서 다음 트랙 명령 수신 (단일 곡 재생 앱으로 지원하지 않음)")
    }
}

/// Control Center에서 이전 트랙 명령 (이 앱에서는 지원하지 않음)  
nonisolated func handlePreviousTrackCommand() {
    print("⏮️ handlePreviousTrackCommand 호출됨!")
    
    Task { @MainActor in
        print("Control Center에서 이전 트랙 명령 수신 (단일 곡 재생 앱으로 지원하지 않음)")
    }
}

// MARK: - UI Slider Support Methods

extension PlayerViewModel {
    
    /// 슬라이더에서 드래그 중일 때 UI 업데이트를 위한 메서드
    public func updateSliderUI(newTime: TimeInterval) {
        currentTime = newTime
        
        guard duration > 0 else {
            progress = 0
            return
        }
        progress = currentTime / duration
        
        // 포맷된 시간 업데이트
        formattedProgress = formattedTime(currentTime)
    }
}
