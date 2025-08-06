//
//  WatchViewModel.swift
//  WatchDancingMarker Watch App
//
//  Created by 변준섭 on 7/16/24.
//

import SwiftUI
import SwiftData

class WatchViewModel: ObservableObject {
    
    // MARK: - Services
    
    internal let communicationService: any WatchCommunicatable
    var connectivityManager: WatchConnectivityManager  // 기존 코드 호환성을 위해 임시 유지
    
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
        self.connectivityManager = connectivityManager
        self.communicationService = WatchCommunicationService(connectivityManager: connectivityManager)
        
        // UserDefaults에서 음악 목록 로드
        self.musicList = UserDefaults.standard.getMusicList()
        
        // 초기화 작업 (Extension에서 구현)
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
