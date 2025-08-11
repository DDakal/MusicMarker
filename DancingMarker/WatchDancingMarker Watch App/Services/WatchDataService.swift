//
//  WatchDataService.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 데이터 관리를 담당하는 서비스
final class WatchDataService: WatchDataManageable {
    
    // MARK: - Properties
    
    private let formatter: DateComponentsFormatter
    
    // MARK: - Initialization
    
    init() {
        // DateComponentsFormatter 설정
        self.formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
    }
    
    // MARK: - UserDefaults Management
    
    func saveMusicList(_ list: [[String]]) {
        UserDefaults.standard.saveMusicList(list)
        print("✅ WatchDataService: 음악 목록 저장 완료 - \(list.count)개")
    }
    
    func getMusicList() -> [[String]] {
        let musicList = UserDefaults.standard.getMusicList()
        print("ℹ️ WatchDataService: 음악 목록 로드 완료 - \(musicList.count)개")
        return musicList
    }
    
    func clearMusicList() {
        UserDefaults.standard.clearMusicList()
        print("🗑️ WatchDataService: 음악 목록 삭제 완료")
    }
    
    // MARK: - Data Processing
    
    func formattedTime(_ time: TimeInterval) -> String {
        return formatter.string(from: time) ?? "0:00"
    }
    
    func processMarkers(_ markers: [TimeInterval]) -> [String] {
        return markers.map { marker in
            if marker != -1 {
                return formattedTime(marker)
            } else {
                return "99:59"
            }
        }
    }
    
    func processPlayingTimes(_ playingTimes: [TimeInterval]) -> (currentTime: TimeInterval, duration: TimeInterval, progress: Double, formattedProgress: String) {
        let currentTime = playingTimes[0]
        let duration = playingTimes[1]
        let progress = duration > 0 ? currentTime / duration : 0
        let formattedProgress = formattedTime(currentTime)
        
        return (currentTime, duration, progress, formattedProgress)
    }
}
