//
//  WatchTimerable.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 타이머 관리를 담당하는 프로토콜
protocol WatchTimerable {
    
    // MARK: - Timer Control
    
    /// 타이머를 시작합니다
    func startTimer()
    
    /// 타이머를 중지합니다
    func stopTimer()
    
    /// 타이머 상태를 확인합니다
    var isTimerRunning: Bool { get }
    
    // MARK: - Timer State Management
    
    /// 타이머 강제 재시작
    func restartTimerIfNeeded(isPlaying: Bool)
    
    /// 타이머 상태를 재생 상태와 동기화
    func syncTimerWithPlayingState(isPlaying: Bool)
    
    // MARK: - Seeking Protection
    
    /// 마커 연타 방지를 위한 보호 메서드
    func withSeekingProtection<T>(_ operation: () async throws -> T) async rethrows -> T?
}

/// 타이머 이벤트를 받는 델리게이트
protocol WatchTimerDelegate: AnyObject {
    func timerDidUpdateTime()
    func timerDidComplete()
}
