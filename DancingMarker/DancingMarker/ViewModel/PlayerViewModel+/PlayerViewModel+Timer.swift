//
//  PlayerViewModel+Timer.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/13/25.
//

import Foundation
import SwiftUI

// MARK: - Timer Management

extension PlayerViewModel {
    
    /// 타이머를 시작합니다
    ///
    /// PlayerViewModel의 진행 상태를 주기적으로 업데이트하며,
    /// AudioService의 상태와 동기화를 유지합니다.
    internal func startTimer() {
        // 기존 타이머 정리
        stopTimer()
        
        // 0.1초마다 업데이트하는 타이머 생성
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePlaybackProgress()
            }
        }
        
        print("PlayerViewModel 타이머 시작됨")
    }
    
    /// 타이머를 중지합니다
    internal func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 재생 진행 상황을 업데이트합니다
    ///
    /// AudioService로부터 현재 재생 상태를 가져와서
    /// PlayerViewModel의 Published 프로퍼티들을 업데이트합니다.
    private func updatePlaybackProgress() async {
        // 드래그 중일 때는 업데이트하지 않음 (사용자 입력 우선)
        guard !isDragging else { return }
        
        do {
            // AudioService에서 현재 상태 가져오기
            let audioCurrentTime = try await audioService.getCurrentTime()
            let audioIsPlaying = audioService.isPlaying
            let audioDuration = audioService.duration
            let audioPlaybackRate = audioService.playbackRate
            
            // 재생 상태가 변경되었는지 확인
            let wasPlaying = isPlaying
            
            // 상태 업데이트
            currentTime = audioCurrentTime
            isPlaying = audioIsPlaying
            duration = audioDuration
            playbackRate = audioPlaybackRate
            
            // UI 관련 계산값 업데이트
            updateProgress()
            updateFormattedTime()
            
            // duration이 변경되면 formatted duration도 업데이트
            if formattedDuration != formattedTime(duration) {
                formattedDuration = formattedTime(duration)
            }
            
            // 재생 상태가 변경된 경우 워치와 Control Center 업데이트
            if wasPlaying != isPlaying {
                await sendPlayingStateToWatch()
                await updateNowPlayingInfo()
            }
            
            // 주기적으로 워치에 시간 정보 전송 (5초마다)
            if Int(currentTime) % 5 == 0 {
                await sendPlayingStateToWatch()
            }
            
        } catch {
            print("재생 진행 상황 업데이트 실패: \(error.localizedDescription)")
            
            // 에러 발생 시 타이머 중지
            if !audioService.isPlaying {
                stopTimer()
            }
        }
    }
    
    /// 사용자가 슬라이더를 드래그할 때 호출됩니다
    /// - Parameter isDragging: 드래그 상태
    func setDragging(_ isDragging: Bool) {
        self.isDragging = isDragging
        
        if isDragging {
            // 드래그 시작: 더 자주 업데이트 (부드러운 UI)
            startHighFrequencyTimer()
        } else {
            // 드래그 종료: 일반 주기로 복원
            startTimer()
        }
    }
    
    /// 드래그 중 고주파 업데이트를 위한 타이머
    private func startHighFrequencyTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updatePlaybackProgress()
            }
        }
    }
    
    /// 타이머 상태를 확인합니다
    var isTimerRunning: Bool {
        return timer != nil
    }
}

// MARK: - Watch Communication (Timer Related)

extension PlayerViewModel {
    
    /// 워치에 재생 상태를 전송합니다 (타이머에서 호출)
    private func sendPlayingStateToWatch() async {
        do {
            try await watchService.sendPlayingState(
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
        } catch {
            print("워치 재생 상태 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// Control Center 정보를 업데이트합니다 (타이머에서 호출)
    private func updateNowPlayingInfo() async {
        guard let music = currentMusic else { return }
        
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
}

// MARK: - Timer Debugging & Monitoring

extension PlayerViewModel {
    
    /// 타이머 관련 디버깅 정보를 반환합니다
    var timerDebugInfo: String {
        return """
        Timer Debug Info:
        - Timer Running: \(isTimerRunning)
        - Is Playing: \(isPlaying)
        - Is Dragging: \(isDragging)
        - Current Time: \(String(format: "%.1f", currentTime))
        - Duration: \(String(format: "%.1f", duration))
        - Progress: \(String(format: "%.2f", progress))
        """
    }
    
    /// 타이머를 강제로 한 번 업데이트합니다 (디버깅용)
    func forceTimerUpdate() async {
        await updatePlaybackProgress()
    }
}
