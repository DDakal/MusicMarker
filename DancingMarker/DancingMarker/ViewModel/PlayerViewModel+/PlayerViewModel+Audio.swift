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
            
            // AudioService를 통해 재생 (URL 기반)
            try await audioService.playMusic(from: musicData.fileURL)
            
            // 마커 정보 로드
            markers = musicData.markers
            
            // 상태 동기화
            await syncAudioServiceState()
            
            // 워치에 재생 정보 전송
            await sendPlayingInformationToWatch()
            
            // Live Activity 업데이트
            await updateNowPlayingInfo()
            
            // 타이머 시작
            startTimer()
            
            print("음악 재생 시작: \(musicData.title)")
            
        } catch {
            print("음악 재생 실패: \(error.localizedDescription)")
        }
    }
    
    /// 재생/일시정지를 토글합니다 (기존 PlayerModel의 togglePlayback 대체)
    func togglePlayback() async {
        do {
            if isPlaying {
                audioService.pause()
                stopTimer()
                print("재생 일시정지")
            } else {
                // AudioService에서 resume 사용
                try await audioService.resume()
                startTimer()
                print("재생 재개")
            }
            
            // 상태 동기화
            await syncAudioServiceState()
            
            // 워치와 Live Activity 업데이트
            await sendPlayingInformationToWatch()
            await updateNowPlayingInfo()
            
        } catch {
            print("재생 토글 실패: \(error.localizedDescription)")
        }
    }
    
    /// 재생을 완전히 중지합니다 (기존 PlayerModel의 stopAudio 대체)
    func stopPlayback() async {
        audioService.stop()
        
        // 상태 초기화
        currentMusic = nil
        isPlaying = false
        currentTime = 0.0
        duration = 0.0
        progress = 0.0
        formattedProgress = "0:00"
        formattedDuration = "0:00"
        
        // 타이머 중지
        stopTimer()
        
        // 워치와 Live Activity 업데이트
        await sendPlayingInformationToWatch()
        await clearNowPlayingInfo()
        
        print("재생 완전 중지")
    }
    
    /// 특정 시간으로 이동합니다 (기존 PlayerModel의 seekToTime 대체)
    /// - Parameter time: 이동할 시간 (초)
    func seek(to time: TimeInterval) async {
        do {
            let seekTime = max(0, min(time, duration))
            try await audioService.seek(to: seekTime)
            
            // 상태 업데이트
            currentTime = seekTime
            updateProgress()
            updateFormattedTime()
            
            // 워치와 Live Activity 업데이트
            await sendPlayingInformationToWatch()
            await updateNowPlayingInfo()
            
        } catch {
            print("탐색 실패: \(error.localizedDescription)")
        }
    }
    
    /// 5초 뒤로 이동합니다 (기존 PlayerModel의 backward5Sec 대체)
    func backward5Seconds() async {
        do {
            try await audioService.skipBackward()
            await syncAudioServiceState()
            await sendPlayingInformationToWatch()
        } catch {
            print("5초 뒤로 이동 실패: \(error.localizedDescription)")
        }
    }
    
    /// 5초 앞으로 이동합니다 (기존 PlayerModel의 forward5Sec 대체)
    func forward5Seconds() async {
        do {
            try await audioService.skipForward()
            await syncAudioServiceState()
            await sendPlayingInformationToWatch()
        } catch {
            print("5초 앞으로 이동 실패: \(error.localizedDescription)")
        }
    }
    
    /// 재생 속도를 변경합니다 (기존 PlayerModel의 setPlaybackRate 관련 대체)
    /// - Parameter rate: 설정할 재생 속도 (0.5 ~ 1.5)
    func setPlaybackRate(_ rate: Float) async {
        do {
            let clampedRate = max(0.5, min(1.5, rate))
            try await audioService.setPlaybackRate(clampedRate)
            
            playbackRate = clampedRate
            
            await sendPlaybackRateToWatch()
            await updateNowPlayingInfo()
            
            print("재생 속도 변경: \(clampedRate)x")
            
        } catch {
            print("재생 속도 변경 실패: \(error.localizedDescription)")
        }
    }
    
    /// 재생 속도를 감소시킵니다 (기존 PlayerModel의 decreasePlaybackRate 대체)
    func decreasePlaybackRate() async {
        let newRate = max(0.5, playbackRate - 0.1)
        await setPlaybackRate(newRate)
    }
    
    /// 재생 속도를 증가시킵니다 (기존 PlayerModel의 increasePlaybackRate 대체)
    func increasePlaybackRate() async {
        let newRate = min(1.5, playbackRate + 0.1)
        await setPlaybackRate(newRate)
    }
    
    /// 재생 속도를 원래대로 돌립니다 (기존 PlayerModel의 originalSpeed 대체)
    func resetPlaybackRate() async {
        await setPlaybackRate(1.0)
    }
    
    /// 볼륨을 설정합니다 (기존 PlayerModel의 setPlayerVolume 대체)
    /// - Parameter volume: 설정할 볼륨 (0.0 ~ 1.0)
    func setVolume(_ volume: Float) async {
        do {
            let clampedVolume = max(0.0, min(1.0, volume))
            
            // AudioService를 통해 볼륨 설정
            try await audioService.setVolume(clampedVolume)
            self.volume = clampedVolume
            
            // 워치에 볼륨 정보 전송
            await sendVolumeToWatch(clampedVolume)
            
            print("볼륨 변경: \(clampedVolume)")
            
        } catch {
            print("볼륨 변경 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Audio State Synchronization

extension PlayerViewModel {
    
    /// AudioService의 상태를 PlayerViewModel과 동기화합니다
    internal func syncAudioServiceState() async {
        do {
            isPlaying = audioService.isPlaying
            currentTime = try await audioService.getCurrentTime()
            duration = audioService.duration
            playbackRate = audioService.playbackRate
            
            updateProgress()
            updateFormattedTime()
            
            // duration이 업데이트되면 formatted duration도 업데이트
            formattedDuration = formattedTime(duration)
        } catch {
            print("상태 동기화 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Handlers (Audio)

extension PlayerViewModel {
    
    /// 워치에서 재생/일시정지 토글 요청 처리
    internal func handlePlayToggle() async {
        countNum += 1
        await togglePlayback()
    }
    
    /// 워치에서 5초 앞으로 이동 요청 처리
    internal func handleForward5Seconds() async {
        countNum += 1
        await forward5Seconds()
    }
    
    /// 워치에서 5초 뒤로 이동 요청 처리
    internal func handleBackward5Seconds() async {
        countNum += 1
        await backward5Seconds()
    }
    
    /// 워치에서 재생 속도 감소 요청 처리
    internal func handleDecreaseSpeed() async {
        countNum += 1
        await decreasePlaybackRate()
    }
    
    /// 워치에서 재생 속도 증가 요청 처리
    internal func handleIncreaseSpeed() async {
        countNum += 1
        await increasePlaybackRate()
    }
    
    /// 워치에서 재생 속도 원래대로 요청 처리
    internal func handleOriginalSpeed() async {
        countNum += 1
        await resetPlaybackRate()
    }
    
    /// 워치에서 특정 음악 재생 요청 처리 (UUID 기반)
    /// - Parameter uuid: 재생할 음악의 UUID
    internal func handleUUIDPlay(_ uuid: String) async {
        countNum += 1
        
        guard let musicId = UUID(uuidString: uuid),
              let selectedMusic = musicList.first(where: { $0.id == musicId }) else {
            print("유효하지 않은 UUID 또는 음악을 찾을 수 없음: \(uuid)")
            return
        }
        
        if currentMusic == nil {
            // 처음 재생하는 경우
            await playMusic(selectedMusic)
            print("음악 \(selectedMusic.title)으로 처음 재생됨")
            
        } else if currentMusic?.id == selectedMusic.id {
            // 현재 재생 중인 음악과 동일한 경우
            if !isPlaying {
                await togglePlayback()
                print("정지된 음악 \(selectedMusic.title) 재생 재개")
            } else {
                print("이미 재생 중인 음악: \(selectedMusic.title)")
            }
            
        } else {
            // 새로운 음악으로 변경하는 경우
            await stopPlayback()
            await playMusic(selectedMusic)
            print("음악 \(selectedMusic.title)으로 변경됨")
        }
    }
    
    /// 워치에서 볼륨 변경 요청 처리
    /// - Parameter volume: 설정할 볼륨 값
    internal func handleVolumeChange(_ volume: Float) async {
        countNum += 1
        await setVolume(volume)
    }
}

// MARK: - Watch Communication (Audio)

extension PlayerViewModel {
    
    /// 워치에 재생 정보를 전송합니다
    private func sendPlayingInformationToWatch() async {
        do {
            // 재생 상태 전송 (프로토콜에 정의된 메서드 사용)
            try await watchService.sendPlayingState(
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
            
            // 음악 제목 전송 (현재 음악이 있는 경우)
            if let music = currentMusic {
                try await watchService.sendMusicTitle("\(music.title) - \(music.artist)")
            }
            
        } catch {
            print("워치 재생 정보 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// 워치에 재생 속도 정보를 전송합니다
    private func sendPlaybackRateToWatch() async {
        do {
            try await watchService.sendPlaybackRate(playbackRate)
        } catch {
            print("워치 재생 속도 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// 워치에 볼륨 정보를 전송합니다
    private func sendVolumeToWatch(_ volume: Float) async {
        do {
            try await watchService.sendSystemVolume(volume)
        } catch {
            print("워치 볼륨 정보 전송 실패: \(error.localizedDescription)")
        }
    }
}

// MARK: - Control Center / Live Activity

extension PlayerViewModel {
    
    /// Now Playing 정보를 업데이트합니다 (기존 updateLiveActivity 대체)
    private func updateNowPlayingInfo() async {
        guard let music = currentMusic else {
            await clearNowPlayingInfo()
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
            
        } catch {
            print("Now Playing 정보 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    /// Now Playing 정보를 초기화합니다 (기존 stopLiveActivity 대체)
    private func clearNowPlayingInfo() async {
        do {
            try await liveActivityService.clearNowPlayingInfo()
        } catch {
            print("Now Playing 정보 초기화 실패: \(error.localizedDescription)")
        }
    }
}
