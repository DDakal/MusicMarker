//
//  WatchViewModel+Timer.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

// MARK: - Timer Management Methods

extension WatchViewModel {
    
    // MARK: - Timer Control
    
    /// 타이머를 시작합니다 (iOS PlayerViewModel 패턴)
    internal func startTimer() {
        // 기존 타이머 정리
        timer?.invalidate()
        
        // 새 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
        
        print("⏰ 타이머 시작됨")
    }
    
    /// 타이머를 중지합니다
    internal func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("⏰ 타이머 중지됨")
    }
    
    /// 시간을 업데이트합니다 (1초마다 호출)
    private func updateTime() {
        // 재생 중이 아니면 업데이트 중지
        guard isPlaying else { 
            print("⏰ 재생 중지 상태 - 타이머 업데이트 생략")
            return 
        }
        
        // 연결이 끊어졌으면 타이머 중지
        guard connectivityManager.isReachable else { 
            print("⚠️ 연결 끊어짐 - 타이머 중지")
            stopTimer()
            return 
        }
        
        // 시간 진행
        currentTime += 1
        
        // 끝에 도달했으면 초기화
        if currentTime >= duration {
            currentTime = 0
            stopTimer()
            isPlaying = false
            print("⏰ 재생 완료 - 타이머 중지")
        }
        
        // UI 업데이트
        progress = duration > 0 ? currentTime / duration : 0
        formattedProgress = formattedTime(currentTime)
    }
    
    // MARK: - Seek Protection (마커 연타 방지)
    
    /// 마커 연타 방지를 위한 보호 메서드 (iOS PlayerViewModel 패턴)
    func withMarkerSeekingProtection<T>(_ operation: () async throws -> T) async rethrows -> T? {
        // 이미 처리 중이면 무시
        guard !isMarkerSeeking else {
            print("⚠️ 마커 이동 중 - 추가 요청 무시")
            return nil
        }
        
        // 플래그 설정
        isMarkerSeeking = true
        
        // 0.8초 후 플래그 해제 (충분한 시간 확보)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            self.isMarkerSeeking = false
            print("✅ 마커 연타 방지 플래그 해제")
        }
        
        // 실제 작업 실행
        return try await operation()
    }
    
    // MARK: - Timer State Management
    
    /// 타이머 상태 확인
    var isTimerRunning: Bool {
        return timer != nil
    }
    
    /// 타이머 강제 재시작 (동기화 후 사용)
    func restartTimerIfNeeded() {
        if isPlaying && !isTimerRunning {
            print("🔄 재생 중인데 타이머가 없음 - 타이머 재시작")
            startTimer()
        }
    }
    
    /// 타이머 상태를 재생 상태와 동기화
    func syncTimerWithPlayingState() {
        if isPlaying && !isTimerRunning {
            startTimer()
        } else if !isPlaying && isTimerRunning {
            stopTimer()
        }
    }
    
    // MARK: - Manual Time Update (동기화용)
    
    /// 수동으로 시간 업데이트 (iOS에서 정확한 시간을 받았을 때)
    func updateTimeFromSync(currentTime: TimeInterval, duration: TimeInterval) {
        print("🔄 iOS에서 정확한 시간 수신 - 업데이트")
        
        self.currentTime = currentTime
        self.duration = duration
        self.progress = duration > 0 ? currentTime / duration : 0
        self.formattedProgress = formattedTime(currentTime)
        
        // 타이머 상태도 동기화
        syncTimerWithPlayingState()
    }
}