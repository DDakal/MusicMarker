//
//  WatchViewModel.swift
//  WatchDancingMarker Watch App
//
//  Created by 변준섭 on 7/16/24.
//

import SwiftUI
import SwiftData

class WatchViewModel: ObservableObject {
    
    // MARK: - Services (모든 Service 주입)
    
    internal let communicationService: any WatchCommunicatable
    internal let syncService: any WatchSyncable
    internal let dataService: any WatchDataManageable  
    internal let timerService: any WatchTimerable
    
    // MARK: - Published Properties (UI 상태만)
    
    @Published var musicTitle: String = ""
    @Published var markers: [String] = ["99:59", "99:59", "99:59"]
    @Published var timeintervalMarkers: [TimeInterval] = [0.0, 0.0, 0.0]
    @Published var speed: Float = 1.0
    @Published var isPlaying = false
    
    @Published var progress: Double = 0.0
    @Published var formattedProgress = "0:00"
    @Published var formattedDuration = "0:00"
    @Published var duration: TimeInterval = 0.0
    @Published var currentTime: TimeInterval = 0.0
    @Published var musicList: [[String]] = []
    
    @Published var crownVolume: Float = 0.5
    @Published var lastSentCrownValue: Float = 0.5
    @Published var hasSelectedMusic: Bool = false
    
    // MARK: - Internal Properties (Extension에서 접근 가능)
    
    internal var timer: Timer?
    internal var isMarkerSeeking: Bool = false
    
    // MARK: - Initialization
    
    init(connectivityManager: WatchConnectivityManager) {
        self.communicationService = WatchCommunicationService(connectivityManager: connectivityManager)
        self.syncService = WatchSyncService(connectivityManager: connectivityManager)
        self.dataService = WatchDataService()
        self.timerService = WatchTimerService(syncService: self.syncService)
        
        // UserDefaults에서 음악 목록 로드
        self.musicList = dataService.getMusicList()
        
        if let timer = timerService as? WatchTimerService {
            timer.delegate = self
        }
        
        // 초기화 작업
        setupNotificationObservers()
    }
    
    convenience init() {
        self.init(connectivityManager: WatchConnectivityManager())
    }
    
    deinit {
        // Timer 정리
        timer?.invalidate()
        timer = nil
        
        // NotificationCenter 정리
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    private enum Keys {
        static let musicList = "musicList"
    }
    
    func saveMusicList(_ list: [[String]]) {
        set(list, forKey: Keys.musicList)
    }
    
    func getMusicList() -> [[String]] {
        return array(forKey: Keys.musicList) as? [[String]] ?? []
    }
    
    func clearMusicList() {
        removeObject(forKey: Keys.musicList)
    }
}

// MARK: - WatchTimerDelegate

extension WatchViewModel: WatchTimerDelegate {
    func timerDidUpdateTime() {
        // 시간 업데이트 로직 (기존 updateTime 내용)
        currentTime += 1
        if currentTime >= duration {
            currentTime = 0
            timerService.stopTimer()
            isPlaying = false
            print("⏰ 재생 완료")
        }
        
        progress = duration > 0 ? currentTime / duration : 0
        formattedProgress = dataService.formattedTime(currentTime)
    }
    
    func timerDidComplete() {
        isPlaying = false
        print("⏰ 타이머 완료")
    }
}
