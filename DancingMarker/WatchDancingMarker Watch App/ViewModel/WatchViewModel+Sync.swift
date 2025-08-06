//
//  WatchViewModel+Sync.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

// MARK: - Sync Methods

extension WatchViewModel {
    
    // MARK: - ApplicationContext 처리 메서드들
    
    /// ApplicationContext에서 음악 목록을 로드합니다
    func loadMusicListFromApplicationContext() {
        if let musicList = connectivityManager.getMusicListFromApplicationContext() {
            print("✅ WatchViewModel: ApplicationContext에서 음악 목록 로드: \(musicList.count)개")
            
            // UserDefaults에 저장
            UserDefaults.standard.clearMusicList()
            UserDefaults.standard.saveMusicList(musicList)
            
            // ViewModel 업데이트
            DispatchQueue.main.async {
                self.musicList = musicList
            }
            
            return
        }
        
        print("ℹ️ WatchViewModel: ApplicationContext에 음악 목록 없음")
    }
    
    /// ApplicationContext가 유효한지 확인합니다
    func isApplicationContextValid() -> Bool {
        return connectivityManager.isApplicationContextValid()
    }
    
    /// ApplicationContext에서 마지막 업데이트 시간을 가져옵니다
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval? {
        return connectivityManager.getLastUpdateTimeFromApplicationContext()
    }
    
    /// 통합 동기화 메서드 (ApplicationContext + 실시간 요청)
    func syncMusicListOnAppear() async {
        print("🎯 WatchViewModel: 통합 동기화 시작")
        
        // 1단계: ApplicationContext 먼저 확인
        loadMusicListFromApplicationContext()
        
        // 2단계: 연결 대기 후 실시간 요청
        await waitForConnectionAndRequestSync()
    }
    
    /// 연결 대기 후 실시간 동기화 요청
    private func waitForConnectionAndRequestSync() async {
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
            
            // ✅ 0.1초 대기 (100ms)
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // 실시간 동기화 요청
        print("   - iOS 앱에 실시간 동기화 요청")
        connectivityManager.sendRequireMusicListToIOS()
    }

    /// 워치에 현재 재생 상태를 전송합니다
    func sendPlayingStateToWatch() async {
        print("🎯 iOS: sendPlayingStateToWatch 시작")
        print("   - isPlaying: \(isPlaying)")
        print("   - currentTime: \(currentTime)")
        print("   - duration: \(duration)")
    }
    
    // MARK: - Background Sync Methods
    
    /// 앱이 백그라운드에서 포그라운드로 올 때 동기화
    func syncOnAppBecomesActive() async {
        print("🔄 앱 활성화 감지 - 동기화 시작")
        
        // ApplicationContext 먼저 확인
        loadMusicListFromApplicationContext()
        
        // 연결되어 있다면 실시간 요청도 보내기
        if connectivityManager.isReachable {
            connectivityManager.sendRequireMusicListToIOS()
            
            // 0.5초 후 재시도 (안정성)
            try? await Task.sleep(for: .milliseconds(500))
            connectivityManager.sendRequireMusicListToIOS()
        }
    }
    
    /// 강제 전체 동기화 (사용자가 수동으로 새로고침할 때)
    func forceFullSync() async {
        print("🔄 강제 전체 동기화 시작")
        
        // 1단계: ApplicationContext 로드
        loadMusicListFromApplicationContext()
        
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