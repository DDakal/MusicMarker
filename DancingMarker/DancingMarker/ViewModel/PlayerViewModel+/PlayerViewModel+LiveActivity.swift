//
//  PlayerViewModel+LiveActivity.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/5/25.
//

import Foundation
import MediaPlayer

// MARK: - RemoteControlHandler Conformance

extension PlayerViewModel: RemoteControlHandler {
    
    // MARK: - Control Center Setup & Update
    
    /// Control Center 및 Live Activity를 설정하고 핸들러를 등록합니다.
    func setupControlCenter() {
        Task {
            do {
                // 핸들러로 self(PlayerViewModel)를 전달하여 원격 제어 명령을 수신할 수 있도록 설정
                try await liveActivityService.setupRemoteControlHandlers(self)
                print("✅ Control Center 핸들러 설정 완료")
            } catch {
                print("❌ Control Center 핸들러 설정 실패: \(error)")
            }
        }
    }
    
    /// Control Center의 재생 정보를 업데이트합니다.
    /// 현재 재생 상태 (시간, 곡 정보 등)가 변경될 때마다 호출됩니다.
    func updateControlCenterInfo() {
        guard let music = self.music else { return }
        
        // NowPlayingInfo 구조체 생성
        let nowPlayingInfo = NowPlayingInfo(
            title: music.title,
            artist: music.artist,
            currentTime: self.currentTime,
            duration: self.duration,
            isPlaying: self.isPlaying,
            playbackRate: self.playbackRate,
            albumArtData: music.albumArt
        )
        
        Task {
            do {
                // LiveActivityService를 통해 Control Center 정보 업데이트
                try await liveActivityService.updateNowPlayingInfo(nowPlayingInfo)
            } catch {
                print("❌ NowPlayingInfo 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// Control Center의 정보를 초기화합니다.
    func clearControlCenterInfo() {
        Task {
            do {
                try await liveActivityService.clearNowPlayingInfo()
            } catch {
                print("❌ NowPlayingInfo 초기화 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Remote Control Event Handlers
    
    /// 재생/일시정지 토글 명령 처리
    func handlePlayPauseCommand() {
        print("▶️⏸️ PlayerViewModel.handlePlayPauseCommand() 호출됨")
        self.playOrPause()
    }
    
    /// 5초 뒤로가기 명령 처리
    func handleSkipBackwardCommand() {
        self.seek(by: -5.0)
    }
    
    /// 5초 앞으로가기 명령 처리
    func handleSkipForwardCommand() {
        self.seek(by: 5.0)
    }
    
    /// 재생 위치 변경 명령 처리
    func handleChangePlaybackPositionCommand(to position: TimeInterval) {
        self.seek(to: position)
    }
    
    // 다음/이전 트랙은 현재 앱에서 지원하지 않으므로 빈 구현을 제공합니다.
    func handleNextTrackCommand() { }
    func handlePreviousTrackCommand() { }
} 