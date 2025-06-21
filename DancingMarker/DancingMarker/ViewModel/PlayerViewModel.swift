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
        // AudioService 상태 관찰 설정
        // TODO: 각 서비스의 Publisher들이 구현되면 연결
        
        // 임시로 기본 설정
        formattedProgress = "0:00"
        formattedDuration = "0:00"
        
        // ✅ WatchService 델리게이트 설정
        watchService.setMessageDelegate(self)
        print("🎯 WatchService 델리게이트 설정 완료")
        
        // ✅ WatchService 세션 활성화
        Task { @MainActor in
            do {
                try await watchService.activateSession()
                print("🎯 WatchService 세션 활성화 완료")
            } catch {
                print("🚨 WatchService 세션 활성화 실패: \(error)")
            }
        }
        
        // ✅ Remote Control 핸들러 설정을 더 강력하게 처리
        print("🎯 PlayerViewModel.setupServiceObservation에서 Remote Control 설정 시작")
        
        Task { @MainActor in
            // 잠시 대기 후 설정 (앱이 완전히 로드된 후)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
            
            print("🎯 Task에서 setupControlCenter 호출 시작")
            setupControlCenter()
            print("🎯 Task에서 setupControlCenter 호출 완료")
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
