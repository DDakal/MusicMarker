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
    
    // 음악 편집 시트 상태 관리 (메인 클래스에 추가)
    @Published var musicToEdit: Music?
    @Published var isEditSheetPresented: Bool = false
    
    // 기타
    @Published var countNum: Int = 0
    
    // MARK: - Internal Properties
    
    internal let formatter: DateComponentsFormatter
    internal var cancellables = Set<AnyCancellable>()
    internal var lastSeekTask: Task<Void, Never>?
    
    /// Timer는 thread-safe하므로 nonisolated context에서도 안전하게 접근 가능
    nonisolated(unsafe) internal var timer: Timer?
    
    internal var isMarkerSeeking: Bool = false

    /// MarkerService 인스턴스에 직접 접근할 수 있도록 하는 computed property
    /// PlayingView에서 편집 중인 마커에 직접 접근할 때 사용됩니다
    var markerServiceInstance: (any MarkerManageable)? {
        return markerService
    }
    
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

// MARK: - UI Actions (View 전용 Public 인터페이스)

extension PlayerViewModel {
    
    /// 재생 속도 증가 (View에서 호출)
    public func increasePlaybackSpeed() async {
        let newRate = min(1.5, playbackRate + 0.1)
        do {
            try await setPlaybackRate(newRate)
            await sendPlaybackRateToWatch()
            print("UI에서 속도 증가: \(newRate)x")
        } catch {
            print("UI 속도 증가 중 오류: \(error)")
        }
    }
    
    /// 재생 속도 감소 (View에서 호출)
    public func decreasePlaybackSpeed() async {
        let newRate = max(0.5, playbackRate - 0.1)
        do {
            try await setPlaybackRate(newRate)
            await sendPlaybackRateToWatch()
            print("UI에서 속도 감소: \(newRate)x")
        } catch {
            print("UI 속도 감소 중 오류: \(error)")
        }
    }
    
    /// 재생 속도 리셋 (View에서 호출)
    public func resetPlaybackSpeed() async {
        do {
            try await setPlaybackRate(1.0)
            await sendPlaybackRateToWatch()
            print("UI에서 속도 리셋: 1.0x")
        } catch {
            print("UI 속도 리셋 중 오류: \(error)")
        }
    }
    
    /// 재생/일시정지 토글 (View에서 호출)
    public func togglePlayback() async {
        do {
            if isPlaying {
                pauseMusic()
                print("UI에서 일시정지")
            } else {
                if currentMusic != nil {
                    try await resumeMusic()
                    print("UI에서 재생")
                } else {
                    print("UI: 재생할 음악이 없음")
                }
            }
            
            await sendPlayingStateToWatch()
            
        } catch {
            print("UI 재생 토글 중 오류: \(error)")
        }
    }

    /// 음원 편집 저장 (View에서 호출) 
    public func saveMusicEdit(
        music: Music,
        title: String,
        artist: String,
        albumArt: UIImage?
    ) async {
        // 음원 정보 업데이트
        music.title = title
        music.artist = artist
        music.albumArt = albumArt?.pngData()
        
        do {
            // Core Data 저장
            try modelContext.save()
            
            // PlayerViewModel의 currentMusic 업데이트
            if currentMusic?.id == music.id {
                let updatedMusicData = MusicData(
                    id: music.id,
                    title: music.title,
                    artist: music.artist,
                    fileName: music.fileName,
                    markers: music.markers,
                    albumArt: music.albumArt
                )
                currentMusic = updatedMusicData
                
                // Control Center 업데이트
                await updateControlCenterNowPlaying()
                
                print("✅ UI에서 음원 편집 완료: \(updatedMusicData.title)")
            }
            
            await sendMusicListToWatch()
            
        } catch {
            print("❌ UI 음원 편집 저장 실패: \(error.localizedDescription)")
        }
    }

    /// 음원 선택해서 재생 (View에서 호출)
    public func selectAndPlayMusic(
        _ music: Music,
        navigationManager: NavigationManager
    ) async {
        let musicData = MusicData(
            id: music.id,
            title: music.title,
            artist: music.artist,
            fileName: music.fileName,
            markers: music.markers,
            albumArt: music.albumArt
        )
        
        do {
            if currentMusic == nil || currentMusic?.id != musicData.id {
                await playMusic(musicData)
            } else if !isPlaying {
                try await resumeMusic()
            }
            
            navigationManager.push(to: .playing)
            print("✅ UI에서 음원 선택: \(musicData.title)")
            
        } catch {
            print("❌ UI 음원 선택 중 오류: \(error.localizedDescription)")
        }
    }
    
    /// 음원 삭제 (View에서 호출)
    public func deleteMusicFromList(
        _ music: Music,
        modelContext: ModelContext
    ) async {
        // 현재 재생 중인 음악이면 정지
        if currentMusic?.id == music.id {
            await stopMusic()
        }
        
        do {
            modelContext.delete(music)
            try modelContext.save()
            await sendMusicListToWatch()
            print("✅ UI에서 음원 삭제: \(music.title)")
        } catch {
            print("❌ UI 음원 삭제 중 오류: \(error)")
        }
    }
    
    /// 새 음원 추가 (View에서 호출) 
    public func addMusicToList(
        from url: URL,
        modelContext: ModelContext
    ) async {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Security scoped resource 접근 실패")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let (title, artist, albumArt) = try await fetchMusicMetadata(from: url)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let uniqueFileURL = documentsDirectory.appendingUniquePathComponent(url.lastPathComponent)
            
            try FileManager.default.copyItem(at: url, to: uniqueFileURL)
            
            let newMusic = Music(
                title: title,
                artist: artist,
                fileName: uniqueFileURL.lastPathComponent,
                markers: [-1, -1, -1],
                albumArt: albumArt
            )
            
            modelContext.insert(newMusic)
            try modelContext.save()
            
            await sendMusicListToWatch()
            print("✅ UI에서 새 음원 추가: \(title)")
        } catch {
            print("❌ UI 음원 추가 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchMusicMetadata(from url: URL) async throws -> (String, String, Data?) {
        let asset = AVAsset(url: url)
        let metadata = try await asset.load(.commonMetadata)
        
        var title: String? = nil
        var artist: String? = nil
        var albumArt: Data? = nil
        
        for item in metadata {
            if item.commonKey == .commonKeyTitle,
               let loadedTitle = try await item.load(.stringValue) {
                title = loadedTitle
            }
            if item.commonKey == .commonKeyArtist,
               let loadedArtist = try await item.load(.stringValue) {
                artist = loadedArtist
            }
            if item.commonKey == .commonKeyArtwork {
                albumArt = try await item.load(.dataValue)
            }
        }
        
        // 기본값 처리
        if title == nil || title == "Unknown Title" {
            title = url.deletingPathExtension().lastPathComponent
        }
        
        if artist == nil || artist == "Unknown Artist" {
            artist = "Unknown Artist"
        }
        
        return (title!, artist!, albumArt)
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

// MARK: - UI State Management (MusicList 관련)

extension PlayerViewModel {
    
    // MARK: - UI Actions for MusicList
    
    /// 음악 편집 시트 표시 (타이밍 이슈 해결)
    public func presentMusicEditSheet(for music: Music) {
        musicToEdit = music
        isEditSheetPresented = true
    }
    
    /// 음악 편집 시트 닫기
    public func dismissMusicEditSheet() {
        isEditSheetPresented = false
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
            musicToEdit = nil
        }
    }
    
    /// 음악 편집 저장 후 시트 자동 닫기 (기존 메서드 확장)
    public func saveMusicEditAndDismiss(
        music: Music,
        title: String,
        artist: String,
        albumArt: UIImage?,
        hasChanges: Bool
    ) async {
        
        guard !title.isEmpty && !artist.isEmpty && hasChanges else {
            print("❌ 저장 조건 미충족: title=\(title.isEmpty), artist=\(artist.isEmpty), hasChanges=\(hasChanges)")
            return
        }

        await saveMusicEdit(music: music, title: title, artist: artist, albumArt: albumArt)
        await MainActor.run {
            dismissMusicEditSheet()
        }
    }
}
