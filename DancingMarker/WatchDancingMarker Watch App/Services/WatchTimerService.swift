//
//  WatchTimerService.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 타이머 관리를 담당하는 서비스
final class WatchTimerService: WatchTimerable {
    
    // MARK: - Properties
    
    private var timer: Timer?
    private var isMarkerSeeking: Bool = false
    private let syncService: any WatchSyncable
    
    weak var delegate: WatchTimerDelegate?
    
    // MARK: - Initialization
    
    init(syncService: any WatchSyncable, delegate: WatchTimerDelegate? = nil) {
        self.syncService = syncService
        self.delegate = delegate
    }
    
    // MARK: - Timer Control
    
    func startTimer() {
        // 기존 타이머 정리
        timer?.invalidate()
        
        // 새 타이머 시작
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimerUpdate()
        }
        
        print("⏰ WatchTimerService: 타이머 시작됨")
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("⏰ WatchTimerService: 타이머 중지됨")
    }
    
    var isTimerRunning: Bool {
        return timer != nil
    }
    
    // MARK: - Private Methods
    
    private func handleTimerUpdate() {
        // 연결이 끊어졌으면 타이머 중지
        guard syncService.isReachable else {
            print("⚠️ 연결 끊어짐 - 타이머 중지")
            stopTimer()
            return
        }
        
        // 델리게이트에 업데이트 알림
        delegate?.timerDidUpdateTime()
    }
    
    // MARK: - Timer State Management
    
    func restartTimerIfNeeded(isPlaying: Bool) {
        if isPlaying && !isTimerRunning {
            print("🔄 재생 중인데 타이머가 없음 - 타이머 재시작")
            startTimer()
        }
    }
    
    func syncTimerWithPlayingState(isPlaying: Bool) {
        if isPlaying && !isTimerRunning {
            startTimer()
        } else if !isPlaying && isTimerRunning {
            stopTimer()
        }
    }
    
    // MARK: - Seeking Protection
    
    func withSeekingProtection<T>(_ operation: () async throws -> T) async rethrows -> T? {
        // 이미 처리 중이면 무시
        guard !isMarkerSeeking else {
            print("⚠️ 마커 이동 중 - 추가 요청 무시")
            return nil
        }
        
        // 플래그 설정
        isMarkerSeeking = true
        
        // 0.8초 후 플래그 해제
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            self.isMarkerSeeking = false
            print("✅ 마커 연타 방지 플래그 해제")
        }
        
        // 실제 작업 실행
        return try await operation()
    }
}
