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
    private var isAudioSessionConfigured = false  // ✅ 중복 설정 방지 플래그
    
    // MARK: - Initialization
    
    init() {
        // ✅ init에서 Audio Session 설정 제거
        print("🎧 LiveActivityService 초기화됨")
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
            
            // URL Scheme 설정 - Control Center에서 앱으로 이동할 수 있도록
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackProgress] = info.currentTime / info.duration
            
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
        print("🎯 LiveActivityService.setupRemoteControlHandlers 시작")
        print("🎯 handler 타입: \(type(of: handler))")
        
        // ✅ Audio Session이 아직 설정되지 않았을 때만 설정
        if !isAudioSessionConfigured {
            try await configureAudioSession()
        }
        
        remoteControlHandler = handler
        print("🎯 remoteControlHandler 설정 완료!")
        
        await MainActor.run {
            print("🎯 MainActor에서 Remote Command 설정 시작")
            
            // 기존 핸들러 제거 (하지만 handler는 유지)
            print("🧹 기존 Remote Command 비활성화...")
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = false
            remoteCommandCenter.skipBackwardCommand.isEnabled = false
            remoteCommandCenter.skipForwardCommand.isEnabled = false
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = false
            
            // 타겟 제거
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
            remoteCommandCenter.skipBackwardCommand.removeTarget(nil)
            remoteCommandCenter.skipForwardCommand.removeTarget(nil)
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
            
            print("🧹 기존 핸들러 제거 완료")
            
            // Play/Pause 명령 설정
            remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
            remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
                print("🎵 togglePlayPauseCommand 타겟 호출됨!")
                
                if let strongSelf = self, let handler = strongSelf.remoteControlHandler {
                    print("✅ handler 존재함! handlePlayPauseCommand 호출")
                    handler.handlePlayPauseCommand()
                    print("✅ handlePlayPauseCommand 호출 완료")
                } else {
                    print("❌ self 또는 remoteControlHandler가 nil")
                    print("   - self: \(self != nil ? "존재" : "nil")")
                    print("   - handler: \(self?.remoteControlHandler != nil ? "존재" : "nil")")
                }
                
                return .success
            }
            print("🎯 togglePlayPauseCommand 설정 완료")
            
            // Skip Backward 명령 설정 (5초)
            remoteCommandCenter.skipBackwardCommand.isEnabled = true
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 5)]
            remoteCommandCenter.skipBackwardCommand.addTarget { [weak self] event in
                print("⏪ skipBackwardCommand 타겟 호출됨!")
                
                if let strongSelf = self, let handler = strongSelf.remoteControlHandler {
                    print("✅ handler 존재함! handleSkipBackwardCommand 호출")
                    handler.handleSkipBackwardCommand()
                    print("✅ handleSkipBackwardCommand 호출 완료")
                } else {
                    print("❌ self 또는 remoteControlHandler가 nil")
                }
                
                return .success
            }
            print("🎯 skipBackwardCommand 설정 완료")
            
            // Skip Forward 명령 설정 (5초)
            remoteCommandCenter.skipForwardCommand.isEnabled = true
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 5)]
            remoteCommandCenter.skipForwardCommand.addTarget { [weak self] event in
                print("⏩ skipForwardCommand 타겟 호출됨!")
                
                if let strongSelf = self, let handler = strongSelf.remoteControlHandler {
                    print("✅ handler 존재함! handleSkipForwardCommand 호출")
                    handler.handleSkipForwardCommand()
                    print("✅ handleSkipForwardCommand 호출 완료")
                } else {
                    print("❌ self 또는 remoteControlHandler가 nil")
                }
                
                return .success
            }
            print("🎯 skipForwardCommand 설정 완료")
            
            // 재생 위치 변경 명령 설정
            remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
            remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                print("🎚️ changePlaybackPositionCommand 타겟 호출됨!")
                
                if let positionEvent = event as? MPChangePlaybackPositionCommandEvent,
                   let strongSelf = self, let handler = strongSelf.remoteControlHandler {
                    print("✅ handler 존재함! handleChangePlaybackPositionCommand 호출")
                    handler.handleChangePlaybackPositionCommand(to: positionEvent.positionTime)
                    print("✅ handleChangePlaybackPositionCommand 호출 완료")
                    return .success
                } else {
                    print("❌ 이벤트 캐스팅 실패 또는 handler가 nil")
                    return .commandFailed
                }
            }
            print("🎯 changePlaybackPositionCommand 설정 완료")
            
            print("🎯 모든 Remote Command 설정 완료")
        }
        
        print("✅ LiveActivityService.setupRemoteControlHandlers 완료")
    }
    
    func disableRemoteControlHandlers() {
        print("🧹 Remote Command 비활성화 시작")
        
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
        
        
        print("🧹 Remote Command 비활성화 완료 (handler는 유지)")
    }
    
    func configureAudioSession() async throws {
        // ✅ 이미 설정되었으면 중복 설정하지 않음
        guard !isAudioSessionConfigured else {
            print("🎧 Audio Session 이미 구성됨, 스킵")
            return
        }
        
        print("🎧 Audio Session 구성 시작")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // 현재 상태 확인
            print("🎧 현재 Audio Session 상태: category=\(audioSession.category), active=\(audioSession.isOtherAudioPlaying)")
            
            // ✅ 가장 단순한 설정으로 시작
            try audioSession.setCategory(.playback)
            print("🎧 Audio Session 카테고리 설정 완료")
            
            try audioSession.setActive(true)
            print("🎧 Audio Session 활성화 완료")
            
            isAudioSessionConfigured = true  // ✅ 설정 완료 플래그
            
        } catch {
            print("❌ Audio Session 구성 실패: \(error)")
            
            // 더 자세한 에러 정보 출력
            if let nsError = error as NSError? {
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - LocalizedDescription: \(nsError.localizedDescription)")
            }
            
            throw DancingMarkerError.audioSessionSetupFailed
        }
    }
    
    func deactivateAudioSession() async throws {
        guard isAudioSessionConfigured else {
            print("🎧 Audio Session이 구성되지 않음, 비활성화 스킵")
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
            isAudioSessionConfigured = false  // ✅ 플래그 초기화
            print("🎧 Audio Session 비활성화 완료")
        } catch {
            print("❌ Audio Session 비활성화 실패: \(error)")
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
    
    // ✅ setupAudioSession 메서드 제거 (중복 호출 방지)
    
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
