//
//  WatchViewModel+Sync.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

extension WatchViewModel {
    
    // MARK: - Sync Methods (모든 로직을 Service로 위임)
    
    /// 통합 동기화 메서드 (Service 사용)
    func syncMusicListOnAppear() async {
        await syncService.syncMusicList()
    }
    
    /// ApplicationContext에서 음악 목록을 로드합니다 (Service 사용)
    func loadMusicListFromApplicationContext() {
        if let musicList = syncService.getMusicListFromApplicationContext() {
            print("✅ WatchViewModel: ApplicationContext에서 음악 목록 로드: \(musicList.count)개")
            
            dataService.clearMusicList()
            dataService.saveMusicList(musicList)
            
            // ViewModel 업데이트
            DispatchQueue.main.async {
                self.musicList = musicList
            }
        }
    }
    
    /// ApplicationContext가 유효한지 확인합니다 (Service 사용)
    func isApplicationContextValid() -> Bool {
        return syncService.isApplicationContextValid()
    }
    
    /// ApplicationContext에서 마지막 업데이트 시간을 가져옵니다 (Service 사용)
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval? {
        return syncService.getLastUpdateTimeFromApplicationContext()
    }
    
    /// 앱 활성화 시 동기화 (Service 사용)
    func syncOnAppBecomesActive() async {
        await syncService.syncOnAppBecomesActive()
    }
    
    /// 강제 전체 동기화 (Service 사용)
    func forceFullSync() async {
        await syncService.forceFullSync()
    }
    
    // MARK: - View Lifecycle Methods (WatchMusicListView에서 사용)
    
    /// 앱이 활성화될 때 동기화 (WatchMusicListView.handleSceneActivation에서 호출)
    func handleAppActivation() {
        print("🔄 앱 활성화 - 동기화 시작")
        requestMusicList()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestMusicList()
        }
    }
    
    /// 화면이 나타날 때 동기화 (WatchMusicListView.handleOnAppear에서 호출)
    func handleViewAppear() {
        print("🔄 화면 표시 - 동기화 시작")
        requestMusicList()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestMusicList()
        }
    }
}
