//
//  WatchViewModel+Timer.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

// MARK: - Timer Management Methods

extension WatchViewModel {
    
    // MARK: - Timer Control (Service 사용)
    
    /// 타이머를 시작합니다 (Service 위임)
    internal func startTimer() {
        timerService.startTimer()
    }
    
    /// 타이머를 중지합니다 (Service 위임)
    internal func stopTimer() {
        timerService.stopTimer()
    }
    
    /// 타이머 상태 확인 (Service 위임)
    var isTimerRunning: Bool {
        timerService.isTimerRunning
    }
    
    /// 타이머 강제 재시작 (Service 위임)
    func restartTimerIfNeeded() {
        timerService.restartTimerIfNeeded(isPlaying: isPlaying)
    }
    
    /// 타이머 상태 동기화 (Service 위임)
    func syncTimerWithPlayingState() {
        timerService.syncTimerWithPlayingState(isPlaying: isPlaying)
    }
    
    /// 마커 연타 방지 (Service 위임)
    func withMarkerSeekingProtection<T>(_ operation: () async throws -> T) async rethrows -> T? {
        return try await timerService.withSeekingProtection(operation)
    }
    
    /// 수동으로 시간 업데이트 (iOS에서 정확한 시간을 받았을 때)
    func updateTimeFromSync(currentTime: TimeInterval, duration: TimeInterval) {
        print("🔄 iOS에서 정확한 시간 수신 - 업데이트")
        
        self.currentTime = currentTime
        self.duration = duration
        self.progress = duration > 0 ? currentTime / duration : 0
        self.formattedProgress = dataService.formattedTime(currentTime)
        
        // 타이머 상태도 동기화
        syncTimerWithPlayingState()
    }
}
