//
//  WatchSyncable.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 동기화를 담당하는 프로토콜
protocol WatchSyncable {
    
    // MARK: - ApplicationContext
    
    /// ApplicationContext에서 음악 목록을 가져옵니다
    func getMusicListFromApplicationContext() -> [[String]]?
    
    /// ApplicationContext가 유효한지 확인합니다
    func isApplicationContextValid() -> Bool
    
    /// ApplicationContext에서 마지막 업데이트 시간을 가져옵니다
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval?
    
    // MARK: - Sync Operations
    
    /// 통합 동기화 (ApplicationContext + 실시간 요청)
    func syncMusicList() async
    
    /// 연결 대기 후 실시간 동기화 요청
    func waitForConnectionAndRequestSync() async
    
    /// 앱 활성화 시 동기화
    func syncOnAppBecomesActive() async
    
    /// 강제 전체 동기화
    func forceFullSync() async
    
    // MARK: - Connection Status
    
    /// 현재 연결 상태
    var isReachable: Bool { get }
}
