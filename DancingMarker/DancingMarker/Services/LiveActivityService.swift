//
//  LiveActivityService.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation
import SwiftUI
import MediaPlayer
import AVFoundation

/// Live Activity (Control Center, Lock Screen) 관리를 담당하는 서비스
///
/// 백그라운드 재생 시 Control Center와 Lock Screen에 표시되는
/// 재생 정보와 컨트롤을 관리합니다.
final class LiveActivityService: ControlCenterManageable {
    
    // MARK: - Private Properties
    
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    private weak var remoteControlHandler: RemoteControlHandler?
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        disableRemoteControlHandlers()
    }
    
    // MARK: - ControlCenterManageable Implementation
    
    func updateNowPlayingInfo(_ info: NowPlayingInfo) async throws {
        await MainActor.run {
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            
            // 기본 정보 설정
            nowPlayingInfo[MPMediaItemPropertyTitle] = info.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = info.artist
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = info.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = info.currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = info.isPlaying ? info.playbackRate : 0.0
            
            // 앨범 아트 설정
            if let albumArtData = info.albumArtData,
               let albumArt = UIImage(data: albumArtData) {
                let artwork = MPMediaItemArtwork(boundsSize: albumArt.size) { _ in albumArt }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            } else {
                // 기본 앨범 아트 사용
                if let defaultArt = generateDefaultAlbumArt(),
                   let defaultImage = UIImage(data: defaultArt) {
                    let artwork = MPMediaItemArtwork(boundsSize: defaultImage.size) { _ in defaultImage }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                }
            }
            
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
    
    func clearNowPlayingInfo() async throws {
        await MainActor.run {
            nowPlayingInfoCenter.nowPlayingInfo = nil
        }
    }
    
    func setupRemoteControlHandlers(_ handler: RemoteControlHandler) async throws {
        remoteControlHandler = handler
        
        await MainActor.run {
            // 기존 핸들러 제거
            disableRemoteControlHandlers()
            
            // Play/Pause 명령 설정
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
            remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
                self?.remoteControlHandler?.handlePlayPauseCommand()
                return .success
            }
            
            // Skip Backward 명령 설정 (5초)
            remoteCommandCenter.skipBackwardCommand.isEnabled = true
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [5]
            remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] _ in
                self?.remoteControlHandler?.handleSkipBackwardCommand()
                return .success
            }
            
            // Skip Forward 명령 설정 (5초)
            remoteCommandCenter.skipForwardCommand.isEnabled = true
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [5]
            remoteCommandCenter.skipForwardCommand.addTarget { [weak self] _ in
                self?.remoteControlHandler?.handleSkipForwardCommand()
                return .success
            }
            
            // 재생 위치 변경 명령 설정
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
            remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                    self?.remoteControlHandler?.handleChangePlaybackPositionCommand(to: positionEvent.positionTime)
                    return .success
                }
                return .commandFailed
            }
            
            // 다음/이전 트랙 명령 (선택적)
            remoteCommandCenter.nextTrackCommand.isEnabled = true
            remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
                self?.remoteControlHandler?.handleNextTrackCommand()
                return .success
            }
            
            remoteCommandCenter.previousTrackCommand.isEnabled = true
            remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
                self?.remoteControlHandler?.handlePreviousTrackCommand()
                return .success
            }
        }
    }
    
    func disableRemoteControlHandlers() {
        // 모든 remote command 비활성화
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
        remoteCommandCenter.skipBackwardCommand.isEnabled = false
        remoteCommandCenter.skipForwardCommand.isEnabled = false
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
        remoteCommandCenter.nextTrackCommand.isEnabled = false
        remoteCommandCenter.previousTrackCommand.isEnabled = false
        
        // 타겟 제거
        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.skipBackwardCommand.removeTarget(nil)
        remoteCommandCenter.skipForwardCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        
        remoteControlHandler = nil
    }
    
    func configureAudioSession() async throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            throw DancingMarkerError.audioSessionSetupFailed
        }
    }
    
    func deactivateAudioSession() async throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
        } catch {
            throw DancingMarkerError.audioSessionSetupFailed
        }
    }
    
    func generateDefaultAlbumArt() -> Data? {
        // 기본 앨범 아트 생성 (66x66 크기)
        let size = CGSize(width: 66, height: 66)
        let rect = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 배경색 설정
        UIColor.systemGray5.setFill()
        UIRectFill(rect)
        
        // 음악 아이콘 그리기
        if let musicIcon = UIImage(systemName: "music.note") {
            let iconSize: CGFloat = 30
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            UIColor.systemGray.setFill()
            musicIcon.draw(in: iconRect)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image?.pngData()
    }
    
    func processAlbumArt(_ imageData: Data, targetSize size: CGSize) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let originalImage = UIImage(data: imageData) else {
                    continuation.resume(throwing: DancingMarkerError.controlCenterUpdateFailed)
                    return
                }
                
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                originalImage.draw(in: CGRect(origin: .zero, size: size))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                guard let resizedImage = resizedImage,
                      let processedData = resizedImage.pngData() else {
                    continuation.resume(throwing: DancingMarkerError.controlCenterUpdateFailed)
                    return
                }
                
                continuation.resume(returning: processedData)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        Task {
            try? await configureAudioSession()
        }
    }
    
    // MARK: - Legacy Support Methods (기존 PlayerModel과의 호환성)
    
    /// 기존 PlayerModel의 remoteControlCenterInfo 메서드와 호환
    func updateRemoteControlCenterInfo(music: Music, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool, playbackRate: Float) {
        let info = NowPlayingInfo(
            title: music.title,
            artist: music.artist,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying,
            playbackRate: playbackRate,
            albumArtData: music.albumArt
        )
        
        Task {
            try? await updateNowPlayingInfo(info)
        }
    }
    
    /// 기존 PlayerModel의 setupControlCenterControls 메서드와 호환
    func setupControlCenterControls(handler: RemoteControlHandler) {
        Task {
            try? await setupRemoteControlHandlers(handler)
        }
    }
    
    /// 기존 PlayerModel의 updateNowPlayingControlCenter 메서드와 호환
    func updateNowPlayingControlCenter(currentTime: TimeInterval, playbackRate: Float, isPlaying: Bool) {
        Task { @MainActor in
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }
}

// MARK: - Extensions

extension LiveActivityService {
    
    /// 현재 Live Activity 상태 정보를 반환합니다.
    var isLiveActivityActive: Bool {
        return nowPlayingInfoCenter.nowPlayingInfo != nil
    }
    
    /// Live Activity 디버깅 정보
    var debugInfo: String {
        guard let info = nowPlayingInfoCenter.nowPlayingInfo else {
            return "Live Activity: Inactive"
        }
        
        let title = info[MPMediaItemPropertyTitle] as? String ?? "Unknown"
        let artist = info[MPMediaItemPropertyArtist] as? String ?? "Unknown"
        let duration = info[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0
        let currentTime = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? 0
        
        return """
        Live Activity Debug Info:
        Title: \(title)
        Artist: \(artist)
        Duration: \(duration)
        Current Time: \(currentTime)
        Remote Commands Enabled: \(remoteCommandCenter.togglePlayPauseCommand.isEnabled)
        """
    }
}
