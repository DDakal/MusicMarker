//
//  PlayerViewModel+Audio.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/13/25.
//

import Foundation
import SwiftUI
import AVFoundation

// MARK: - Audio Control Methods

extension PlayerViewModel {
    
    /// 음악을 재생합니다 (기존 PlayerModel의 playAudio, initAudioPlayer 대체)
    /// - Parameter musicData: 재생할 음악 데이터
    func playMusic(_ musicData: MusicData) async {
        do {
            // 현재 음악 설정
            currentMusic = musicData
            
            // 마커 정보 로드
            loadMarkers(from: musicData)
            
            // AudioService로 음악 재생
            try await audioService.playMusic(from: musicData.fileURL)
            
            // 타이머 시작
            startTimer()
            
            // Control Center 설정 (PlayerViewModle+LiveActivity.swift에서 구현)
            await setupControlCenterForNewMusic(musicData)
            
            // 워치에 새 음악 정보 전송 (PlayerViewModel+Watch.swift에서 구현)
            await sendMusicListToWatch()
            await sendMarkersToWatch()
            await sendPlayingStateToWatch()
            
            print("음악 재생 시작: \(musicData.title)")
            
        } catch {
            print("음악 재생 실패: \(error)")
            // 실패 시 상태 초기화
            currentMusic = nil
        }
    }
    
    /// 재생을 일시정지합니다
    func pauseMusic() {
        audioService.pause()
        
        // Control Center 및 워치 업데이트
        Task {
            await notifyAllExternalServicesOfStateChange()
        }
    }
    
    /// 음악 재생을 재개합니다
    func resumeMusic() async throws {
        try await audioService.resume()
        
        // Control Center 및 워치 업데이트
        await notifyAllExternalServicesOfStateChange()
        
        print("음악 재생 재개됨")
    }
    
    /// 음악 재생을 완전히 중지합니다
    func stopMusic() async {
        // AudioService 중지
        audioService.stop()
        
        // 타이머 중지
        stopTimer()
        
        // 상태 초기화
        currentMusic = nil
        isPlaying = false
        currentTime = 0
        progress = 0
        formattedProgress = "0:00"
        
        // Control Center 정리 (PlayerViewModle+LiveActivity.swift에서 구현)
        await cleanupControlCenterOnStop()
        
        // 워치에 중지 상태 알림 (PlayerViewModel+Watch.swift에서 구현)
        await sendPlayingStateToWatch()
        
        print("음악 재생 완전히 중지됨")
    }
    
    /// 5초 뒤로 이동합니다
    func skipBackward() async throws {
        try await audioService.skipBackward()
        await sendCurrentStateToExternalServices()
    }
    
    /// 5초 앞으로 이동합니다
    func skipForward() async throws {
        try await audioService.skipForward()
        await sendCurrentStateToExternalServices()
    }
    
    /// 특정 시간으로 이동합니다
    func seek(to time: TimeInterval) async throws {
        try await audioService.seek(to: time)
        await sendCurrentStateToExternalServices()
    }
    
    /// 재생 속도를 변경합니다
    func setPlaybackRate(_ rate: Float) async throws {
        try await audioService.setPlaybackRate(rate)
        
        // 워치에 속도 변경 전송
        try await watchService.sendPlaybackRate(rate)
        
        // Control Center 업데이트
        await sendCurrentStateToExternalServices()
    }
    
    /// 워치로 음악 리스트를 전송합니다
    func sendMusicListToWatch(_ musicList: [Music]) async throws {
        try await watchService.sendMusicList(musicList)
        print("워치로 음악 리스트 전송 완료: \(musicList.count)개")
    }
}

// MARK: - Notification Handler Methods

extension PlayerViewModel {
    
    /// 재생/일시정지 토글 처리 (워치에서 호출)
    internal func handlePlayToggle() async {
        do {
            if isPlaying {
                pauseMusic()
                print("워치에서 일시정지 명령 수신")
            } else {
                // 현재 음악이 있으면 재개, 없으면 무시
                if currentMusic != nil {
                    try await resumeMusic()
                    print("워치에서 재생 명령 수신")
                } else {
                    print("재생할 음악이 없어 워치 재생 명령 무시")
                }
            }
        } catch {
            print("워치 재생 토글 처리 중 오류: \(error)")
        }
    }
    
    /// 5초 앞으로 이동 처리 (워치에서 호출)
    internal func handleForward5Seconds() async {
        do {
            try await skipForward()
            print("워치에서 5초 앞으로 이동 명령 수신")
        } catch {
            print("워치 5초 앞으로 이동 처리 중 오류: \(error)")
        }
    }
    
    /// 5초 뒤로 이동 처리 (워치에서 호출)
    internal func handleBackward5Seconds() async {
        do {
            try await skipBackward()
            print("워치에서 5초 뒤로 이동 명령 수신")
        } catch {
            print("워치 5초 뒤로 이동 처리 중 오류: \(error)")
        }
    }
}

// MARK: - Private Helper Methods

private extension PlayerViewModel {
    
    /// 현재 상태를 외부 서비스들에 전송합니다
    func sendCurrentStateToExternalServices() async {
        guard let musicData = currentMusic else { return }
        
        do {
            // 워치 상태 업데이트
            try await watchService.sendPlayingState(
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
            
            // Control Center Now Playing 정보 업데이트  
            let nowPlayingInfo = NowPlayingInfo(
                title: musicData.title,
                artist: musicData.artist,
                currentTime: currentTime,
                duration: duration,
                isPlaying: isPlaying,
                playbackRate: playbackRate,
                albumArtData: musicData.albumArt
            )
            
            try await liveActivityService.updateNowPlayingInfo(nowPlayingInfo)
            
        } catch {
            print("외부 서비스 상태 업데이트 실패: \(error)")
        }
    }
}
