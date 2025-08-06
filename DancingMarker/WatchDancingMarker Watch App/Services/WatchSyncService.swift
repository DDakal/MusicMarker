//
//  WatchSyncService.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 동기화 로직을 담당하는 서비스
final class WatchSyncService: WatchSyncable {
    
    // MARK: - Properties
    
    private let connectivityManager: WatchConnectivityManager
    
    // MARK: - Initialization
    
    init(connectivityManager: WatchConnectivityManager) {
        self.connectivityManager = connectivityManager
    }
    
    // MARK: - Connection Status
    
    var isReachable: Bool {
        connectivityManager.isReachable
    }
    
    // MARK: - ApplicationContext
    
    func getMusicListFromApplicationContext() -> [[String]]? {
        return connectivityManager.getMusicListFromApplicationContext()
    }
    
    func isApplicationContextValid() -> Bool {
        return connectivityManager.isApplicationContextValid()
    }
    
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval? {
        return connectivityManager.getLastUpdateTimeFromApplicationContext()
    }
    
    // MARK: - Sync Operations
    
    func syncMusicList() async {
        print("🎯 WatchSyncService: 통합 동기화 시작")
        
        // 1단계: ApplicationContext 먼저 확인
        if let musicList = getMusicListFromApplicationContext() {
            print("✅ ApplicationContext에서 음악 목록 발견: \(musicList.count)개")
            // ApplicationContext 데이터가 있다는 것을 알림
            NotificationCenter.default.post(name: .applicationContextLoaded, object: musicList)
        }
        
        // 2단계: 연결 대기 후 실시간 요청
        await waitForConnectionAndRequestSync()
    }
    
    func waitForConnectionAndRequestSync() async {
        print("   - 연결 대기 시작...")
        
        // 연결 대기 (최대 3초)
        for attempt in 1...30 {
            if connectivityManager.isReachable {
                print("✅ 워치 연결됨! (시도 \(attempt)번째)")
                break
            }
            
            if attempt == 30 {
                print("⚠️ 워치 연결 시간 초과 - ApplicationContext 데이터 사용")
                return
            }
            
            // 0.1초 대기 (100ms)
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // 실시간 동기화 요청
        print("   - iOS 앱에 실시간 동기화 요청")
        connectivityManager.sendRequireMusicListToIOS()
    }
    
    func syncOnAppBecomesActive() async {
        print("🔄 앱 활성화 감지 - 동기화 시작")
        
        // ApplicationContext 먼저 확인
        if let musicList = getMusicListFromApplicationContext() {
            NotificationCenter.default.post(name: .applicationContextLoaded, object: musicList)
        }
        
        // 연결되어 있다면 실시간 요청도 보내기
        if connectivityManager.isReachable {
            connectivityManager.sendRequireMusicListToIOS()
            
            // 0.5초 후 재시도 (안정성)
            try? await Task.sleep(for: .milliseconds(500))
            connectivityManager.sendRequireMusicListToIOS()
        }
    }
    
    func forceFullSync() async {
        print("🔄 강제 전체 동기화 시작")
        
        // 1단계: ApplicationContext 로드
        if let musicList = getMusicListFromApplicationContext() {
            NotificationCenter.default.post(name: .applicationContextLoaded, object: musicList)
        }
        
        // 2단계: 실시간 요청 (여러 번)
        for attempt in 1...3 {
            if connectivityManager.isReachable {
                connectivityManager.sendRequireMusicListToIOS()
                print("   - 동기화 시도 \(attempt)/3")
                
                if attempt < 3 {
                    try? await Task.sleep(for: .milliseconds(500))
                }
            } else {
                print("   - 시도 \(attempt): 연결 안됨")
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
        
        print("✅ 강제 전체 동기화 완료")
    }
}

// MARK: - Notification.Name Extension

extension Notification.Name {
    static let applicationContextLoaded = Notification.Name("ApplicationContextLoaded")
}
