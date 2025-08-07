//
//  WatchDataManageable.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

/// 워치 데이터 관리를 담당하는 프로토콜
protocol WatchDataManageable {
    
    // MARK: - UserDefaults Management
    
    /// 음악 목록을 저장합니다
    func saveMusicList(_ list: [[String]])
    
    /// 음악 목록을 가져옵니다
    func getMusicList() -> [[String]]
    
    /// 음악 목록을 삭제합니다
    func clearMusicList()
    
    // MARK: - Data Processing
    
    /// TimeInterval을 포맷팅된 문자열로 변환합니다
    func formattedTime(_ time: TimeInterval) -> String
    
    /// 마커 데이터를 처리합니다
    func processMarkers(_ markers: [TimeInterval]) -> [String]
    
    /// 재생 시간 데이터를 처리합니다
    func processPlayingTimes(_ playingTimes: [TimeInterval]) -> (currentTime: TimeInterval, duration: TimeInterval, progress: Double, formattedProgress: String)
}
