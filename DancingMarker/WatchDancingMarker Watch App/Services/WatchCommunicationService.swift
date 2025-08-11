//
//  WatchCommunicationService.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/6/25.
//

import Foundation

/// WatchConnectivityManager를 래핑하여 순수 통신 기능만 제공하는 서비스
final class WatchCommunicationService: WatchCommunicatable {
    
    // MARK: - Properties
    
    private let connectivityManager: WatchConnectivityManager
    
    // MARK: - Initialization
    
    init(connectivityManager: WatchConnectivityManager = WatchConnectivityManager()) {
        self.connectivityManager = connectivityManager
    }
    
    // MARK: - Connection Status
    
    var isReachable: Bool {
        connectivityManager.isReachable
    }
    
    // MARK: - Playback Control
    
    func sendPlayToggle() {
        connectivityManager.sendPlayToggleToIOS()
        print("🎮 WatchCommunicationService: 재생/일시정지 토글 전송")
    }
    
    func sendForward() {
        connectivityManager.sendForwardToIOS()
        print("🎮 WatchCommunicationService: 5초 앞으로 전송")
    }
    
    func sendBackward() {
        connectivityManager.sendBackwardToIOS()
        print("🎮 WatchCommunicationService: 5초 뒤로 전송")
    }
    
    func sendIncreasePlayback() {
        connectivityManager.sendIncreasePlaybackToIOS()
        print("🎮 WatchCommunicationService: 재생 속도 증가 전송")
    }
    
    func sendDecreasePlayback() {
        connectivityManager.sendDecreasePlaybackToIOS()
        print("🎮 WatchCommunicationService: 재생 속도 감소 전송")
    }
    
    func sendOriginalPlayback() {
        connectivityManager.sendOriginalPlaybackToIOS()
        print("🎮 WatchCommunicationService: 원래 재생 속도 전송")
    }
    
    // MARK: - Music Selection
    
    func sendMusicSelection(_ musicID: String) {
        connectivityManager.sendUUIDPlayToIOS(musicID)
        print("🎵 WatchCommunicationService: 음악 선택 전송 - ID: \(musicID)")
    }
    
    // MARK: - Marker Control
    
    func sendMarkerPlay(at index: Int) {
        connectivityManager.sendMarkerPlayToIOS(index)
        print("📍 WatchCommunicationService: 마커 재생 전송 - 인덱스: \(index)")
    }
    
    func sendMarkerSave(at index: Int) {
        connectivityManager.sendMarkerSaveToIOS(index)
        print("📍 WatchCommunicationService: 마커 저장 전송 - 인덱스: \(index)")
    }
    
    func sendMarkerDelete(at index: Int) {
        connectivityManager.sendMarkerDeleteToIOS(index)
        print("📍 WatchCommunicationService: 마커 삭제 전송 - 인덱스: \(index)")
    }
    
    func sendMarkerEditSuccess(index: Int, time: Int) {
        connectivityManager.sendMarkerEditSuccessToIOS(forEdit: [index, time])
        print("📍 WatchCommunicationService: 마커 편집 완료 전송 - 인덱스: \(index), 시간: \(time)")
    }
    
    // MARK: - Volume Control
    
    func sendVolumeChange(_ volume: Float) {
        connectivityManager.sendVolumeChangeToIOS(volume)
        print("🔊 WatchCommunicationService: 볼륨 변경 전송 - \(volume)")
    }
    
    // MARK: - Sync Requests
    
    func requestMusicList() {
        connectivityManager.sendRequireMusicListToIOS()
        print("🔄 WatchCommunicationService: 음악 목록 요청 전송")
    }
    
    func requestCurrentState() {
        connectivityManager.sendRequireCurrentStateToIOS()
        print("🔄 WatchCommunicationService: 현재 상태 동기화 요청 전송")
    }
}
