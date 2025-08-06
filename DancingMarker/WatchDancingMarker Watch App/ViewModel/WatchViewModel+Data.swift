//
//  WatchViewModel+Data.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

// MARK: - Data Management Methods

extension WatchViewModel {
    
    // MARK: - Setup Methods
    
    /// NotificationCenter 옵저버 설정 (iOS 패턴 - 클로저 기반)
    func setupNotificationObservers() {
        // 마커 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendMarkers,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdateMarkers(notification)
        }
        
        // 재생 속도 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendSpeed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdateSpeed(notification)
        }
        
        // 재생 상태 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendIsPlaying,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdateIsPlaying(notification)
        }
        
        // 재생 시간 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendPlayingTimes,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdatePlayingTimes(notification)
        }
        
        // 음악 목록 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendMusicList,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdateMusicList(notification)
        }
        
        // 음악 제목 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendMusicTitle,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleUpdateMusicTitle(notification)
        }
        
        // 시스템 볼륨 업데이트
        NotificationCenter.default.addObserver(
            forName: .sendSystemVolume,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleSetVolumeBySystem(notification)
        }
    }
    
    // MARK: - Data Update Handlers 
    
    private func handleUpdateMarkers(_ notification: Notification) {
        if let markers = notification.object as? [TimeInterval] {
            self.timeintervalMarkers = markers
            self.markers = dataService.processMarkers(markers)
        }
    }
    
    private func handleUpdateSpeed(_ notification: Notification) {
        if let speed = notification.object as? Float {
            self.speed = speed
        }
    }
    
    private func handleUpdateIsPlaying(_ notification: Notification) {
        if let isPlaying = notification.object as? Bool {
            self.isPlaying = isPlaying
            
            timerService.syncTimerWithPlayingState(isPlaying: isPlaying)
        } else {
            print("❌ 워치: isPlaying 값 추출 실패")
            print("   - notification.object 타입: \(type(of: notification.object))")
        }
    }
        
    private func handleUpdatePlayingTimes(_ notification: Notification) {
        if let playingTimes = notification.object as? [TimeInterval] {
            let processed = dataService.processPlayingTimes(playingTimes)
            
            self.currentTime = processed.currentTime
            self.duration = processed.duration
            self.progress = processed.progress
            self.formattedProgress = processed.formattedProgress
            
            // duration > 0이면 음원이 로드된 상태
            if self.duration > 0 {
                self.hasSelectedMusic = true
            }
        }
    }
        
    private func handleUpdateMusicList(_ notification: Notification) {
        if let musics = notification.object as? [[String]] {
            dataService.clearMusicList()
            dataService.saveMusicList(musics)
            self.musicList = musics
            self.hasSelectedMusic = false
        }
    }
    
    private func handleUpdateMusicTitle(_ notification: Notification) {
        if let musicTitle = notification.object as? String {
            self.musicTitle = musicTitle
        }
    }
    
    private func handleSetVolumeBySystem(_ notification: Notification) {
        if let systemVolume = notification.object as? Float {
            self.crownVolume = systemVolume * 60
        }
    }
    
    // MARK: - Utility Methods
    
    /// 시간을 포맷팅합니다
    func formattedTime(_ time: TimeInterval) -> String {
        return dataService.formattedTime(time)
    }
}
