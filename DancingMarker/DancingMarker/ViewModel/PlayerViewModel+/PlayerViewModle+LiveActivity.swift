//
//  PlayerViewModle+LiveActivity.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/21/25.
//

import Foundation
import SwiftUI
import MediaPlayer

// MARK: - Live Activity & Control Center Management

extension PlayerViewModel: RemoteControlHandler {
    
    // MARK: - Now Playing Info Management
    
    /// Control Center에 현재 재생 정보를 업데이트합니다
    func updateControlCenterNowPlaying() async {
        guard let music = currentMusic else {
            await clearControlCenterInfo()
            return
        }
        
        do {
            let nowPlayingInfo = NowPlayingInfo(
                title: music.title,
                artist: music.artist,
                currentTime: currentTime,
                duration: duration,
                isPlaying: isPlaying,
                playbackRate: playbackRate,
                albumArtData: music.albumArt
            )
            
            try await liveActivityService.updateNowPlayingInfo(nowPlayingInfo)
            print("Control Center 정보 업데이트 완료: \(music.title)")
            
        } catch {
            print("Control Center 정보 업데이트 실패: \(error)")
        }
    }
    
    /// Control Center 정보를 초기화합니다
    func clearControlCenterInfo() async {
        do {
            try await liveActivityService.clearNowPlayingInfo()
            print("Control Center 정보 초기화 완료")
        } catch {
            print("Control Center 정보 초기화 실패: \(error)")
        }
    }
    
    /// Control Center에 현재 재생 시간만 업데이트합니다 (타이머용)
    func updateControlCenterPlaybackTime() async {
        guard currentMusic != nil else { return }
        
        // 주기적 업데이트를 위해 간소화된 정보만 전송
        await updateControlCenterNowPlaying()
    }
    
    // MARK: - Remote Control Setup
    
    /// Remote Control 명령 핸들러를 설정합니다
    internal func setupRemoteControlHandlers() {
        print("🎯 setupRemoteControlHandlers 호출됨")
        print("🎯 현재 스레드: \(Thread.isMainThread ? "Main" : "Background")")
        print("🎯 PlayerViewModel 인스턴스: \(self)")
        
        Task {
            do {
                print("🎯 LiveActivityService.setupRemoteControlHandlers 호출 시작")
                print("🎯 liveActivityService: \(liveActivityService)")
                
                try await liveActivityService.setupRemoteControlHandlers(self)
                
                print("✅ Remote Control 핸들러 설정 완료")
                
                // ✅ 설정 후 바로 테스트로 Now Playing Info 업데이트
                await updateControlCenterNowPlaying()
                
            } catch {
                print("❌ Remote Control 핸들러 설정 실패: \(error)")
            }
        }
    }
    
    /// Remote Control 명령 핸들러를 비활성화합니다
    func disableRemoteControlHandlers() {
        liveActivityService.disableRemoteControlHandlers()
        print("Remote Control 핸들러 비활성화 완료")
    }
    
    // MARK: - Audio Session Management
    
    /// 백그라운드 재생을 위한 오디오 세션을 구성합니다
    func configureBackgroundAudioSession() async {
        do {
            try await liveActivityService.configureAudioSession()
            print("백그라운드 오디오 세션 구성 완료")
        } catch {
            print("백그라운드 오디오 세션 구성 실패: \(error)")
        }
    }
    
    /// 오디오 세션을 비활성화합니다
    func deactivateAudioSession() async {
        do {
            try await liveActivityService.deactivateAudioSession()
            print("오디오 세션 비활성화 완료")
        } catch {
            print("오디오 세션 비활성화 실패: \(error)")
        }
    }
}

// MARK: - RemoteControlHandler Implementation

extension PlayerViewModel {
    
    /// Control Center에서 재생/일시정지 버튼을 눌렀을 때
    func handlePlayPauseCommand() {
        print("🎵 handlePlayPauseCommand 호출됨!")
        
        Task { @MainActor in
            if isPlaying {
                pauseMusic()
                print("Control Center에서 일시정지 명령 수신")
            } else {
                if currentMusic != nil {
                    do {
                        try await resumeMusic()
                        print("Control Center에서 재생 명령 수신")
                    } catch {
                        print("Control Center 재생 명령 처리 중 오류: \(error)")
                    }
                }
            }
        }
    }
    
    /// Control Center에서 5초 뒤로 이동 명령
    func handleSkipBackwardCommand() {
        print("⏪ handleSkipBackwardCommand 호출됨!")
        
        Task { @MainActor in
            do {
                try await skipBackward()
                await updateControlCenterNowPlaying()
                print("Control Center에서 5초 뒤로 이동 명령 수신")
            } catch {
                print("Control Center 5초 뒤로 이동 처리 중 오류: \(error)")
            }
        }
    }
    
    /// Control Center에서 5초 앞으로 이동 명령
    func handleSkipForwardCommand() {
        print("⏩ handleSkipForwardCommand 호출됨!")
        
        Task { @MainActor in
            do {
                try await skipForward()
                await updateControlCenterNowPlaying()
                print("Control Center에서 5초 앞으로 이동 명령 수신")
            } catch {
                print("Control Center 5초 앞으로 이동 처리 중 오류: \(error)")
            }
        }
    }
    
    /// Control Center에서 재생 위치 변경 명령
    func handleChangePlaybackPositionCommand(to position: TimeInterval) {
        print("🎚️ handleChangePlaybackPositionCommand 호출됨! position: \(position)")
        
        Task { @MainActor in
            do {
                try await seek(to: position)
                await updateControlCenterNowPlaying()
                print("Control Center에서 재생 위치 변경 명령 수신: \(formattedTime(position))")
            } catch {
                print("Control Center 재생 위치 변경 처리 중 오류: \(error)")
            }
        }
    }
    
    /// Control Center에서 다음 트랙 명령 (추후 구현)
    func handleNextTrackCommand() {
        print("⏭️ handleNextTrackCommand 호출됨!")
        
        Task { @MainActor in
            // TODO: 다음 곡 기능 구현
            print("Control Center에서 다음 트랙 명령 수신 (미구현)")
        }
    }
    
    /// Control Center에서 이전 트랙 명령 (추후 구현)
    func handlePreviousTrackCommand() {
        print("⏮️ handlePreviousTrackCommand 호출됨!")
        
        Task { @MainActor in
            // TODO: 이전 곡 기능 구현
            print("Control Center에서 이전 트랙 명령 수신 (미구현)")
        }
    }
}

// MARK: - Music Lifecycle Integration

extension PlayerViewModel {
    
    /// 새 음악 재생 시 Control Center 설정
    func setupControlCenterForNewMusic(_ musicData: MusicData) async {
        // ✅ Audio Session 설정을 여기서 하지 않음 (setupRemoteControlHandlers에서 처리)
        await updateControlCenterNowPlaying()
        print("새 음악에 대한 Control Center 설정 완료: \(musicData.title)")
    }
    
    /// 음악 중지 시 Control Center 정리
    func cleanupControlCenterOnStop() async {
        await clearControlCenterInfo()
        print("음악 중지에 따른 Control Center 정리 완료")
    }
    
    /// 재생 상태 변경 시 Control Center 업데이트
    func notifyControlCenterOfPlaybackStateChange() async {
        await updateControlCenterNowPlaying()
    }
    
    /// 마커 이동 시 Control Center 업데이트
    func notifyControlCenterOfMarkerJump() async {
        await updateControlCenterNowPlaying()
    }
}

// MARK: - Live Activity Debugging & Monitoring

extension PlayerViewModel {
    
    /// Control Center 상태 디버깅 정보
    var controlCenterDebugInfo: String {
        guard let music = currentMusic else {
            return "Control Center: No music playing"
        }
        
        return """
        Control Center Debug Info:
        - Title: \(music.title)
        - Artist: \(music.artist)
        - Current Time: \(formattedTime(currentTime))
        - Duration: \(formattedTime(duration))
        - Is Playing: \(isPlaying)
        - Playback Rate: \(playbackRate)x
        - Has Album Art: \(music.albumArt != nil)
        """
    }
    
    /// Control Center 정보를 강제로 업데이트합니다 (디버깅용)
    func forceControlCenterUpdate() async {
        await updateControlCenterNowPlaying()
        print("Control Center 강제 업데이트 실행")
    }
}

// MARK: - Integration with Other Extensions

extension PlayerViewModel {
    
    /// 다른 extension에서 호출할 수 있는 통합 업데이트 메서드
    func updateExternalServices() async {
        await withTaskGroup(of: Void.self) { group in
            // Control Center 업데이트
            group.addTask {
                await self.updateControlCenterNowPlaying()
            }
            
            // 워치 업데이트 (PlayerViewModel+Watch.swift에서 구현)
            group.addTask {
                await self.sendPlayingStateToWatch()
            }
        }
    }
    
    /// 재생 상태 변경 시 모든 외부 서비스에 알림
    func notifyAllExternalServicesOfStateChange() async {
        await updateExternalServices()
    }
}
