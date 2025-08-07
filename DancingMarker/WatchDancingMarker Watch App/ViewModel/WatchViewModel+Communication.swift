//
//  WatchViewModel+Communication.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/7/25.
//

import Foundation

// MARK: - Communication Methods

extension WatchViewModel {
    
    // MARK: - Playback Control (View 전용 Public 인터페이스)
    
    /// 재생/일시정지 토글 (View에서 호출)
    func playToggle() {
        communicationService.sendPlayToggle()
    }
    
    /// 5초 앞으로 이동 (View에서 호출)
    func playForward() {
        communicationService.sendForward()
    }
    
    /// 5초 뒤로 이동 (View에서 호출)
    func playBackward() {
        communicationService.sendBackward()
    }
    
    /// 재생 속도 감소 (View에서 호출)
    func decreasePlaybackRate() {
        communicationService.sendDecreasePlayback()
    }
    
    /// 재생 속도 증가 (View에서 호출)
    func increasePlaybackRate() {
        communicationService.sendIncreasePlayback()
    }
    
    /// 원래 재생 속도로 복원 (View에서 호출)
    func originalPlaybckRate() {
        communicationService.sendOriginalPlayback()
    }
    
    // MARK: - Music Selection (View 전용 Public 인터페이스)
    
    /// UUID로 음악 선택 (View에서 호출)
    func sendUUID(id: String) {
        communicationService.sendMusicSelection(id)
        self.hasSelectedMusic = true
    }
    
    // MARK: - Marker Actions (View 전용 Public 인터페이스)
    
    /// 마커 저장 또는 재생 (View에서 호출)
    func handleMarkerTap(at index: Int) {
        if isMarkerEmpty(at: index) {
            saveMarker(at: index)
        } else {
            playMarker(at: index)
        }
    }
    
    /// 마커 저장 (View에서 호출)
    func saveMarker(at index: Int) {
        communicationService.sendMarkerSave(at: index)
        print("✅ ViewModel: 마커 \(index) 저장 요청")
    }
    
    /// 마커 재생 (View에서 호출)
    func playMarker(at index: Int) {
        communicationService.sendMarkerPlay(at: index)
        print("✅ ViewModel: 마커 \(index) 재생 요청")
    }
    
    /// 마커 삭제 (View에서 호출)
    func deletemarker(index: Int) {
        communicationService.sendMarkerDelete(at: index)
    }
    
    /// 마커 편집 완료 (View에서 호출)
    func saveMarkerEdit(index: Int, time: Int) {
        communicationService.sendMarkerEditSuccess(index: index, time: time)
        print("✅ ViewModel: 마커 \(index) 편집 완료 - 시간: \(time)")
    }
    
    /// 마커가 비어있는지 확인 (View에서 호출)
    func isMarkerEmpty(at index: Int) -> Bool {
        return markers[index] == "99:59"
    }
    
    // MARK: - Volume Control (View 전용 Public 인터페이스)
    
    /// 볼륨 변경 (View에서 호출)
    func changeVolume() {
        let volumeToSend = self.crownVolume / 60
        communicationService.sendVolumeChange(volumeToSend)
    }
    
    /// Crown 값 변경 처리 (View에서 호출)
    func handleCrownValueChange(_ newValue: Float) {
        // 일정 수준 이상 변화했을 때만 iOS로 메시지 전송
        let threshold: Float = 0.05  // 변화 임계값
        if abs(newValue - lastSentCrownValue) >= threshold {
            let volumeToSend = self.crownVolume / 60
            communicationService.sendVolumeChange(volumeToSend)
            lastSentCrownValue = newValue  // 마지막 전송 값 업데이트
        }
    }
    
    // MARK: - Music List Sync Actions (View 전용 Public 인터페이스)
    
    /// 음악 목록 동기화 요청 (View에서 호출)
    func requestMusicList() {
        communicationService.requestMusicList()
        print("✅ ViewModel: 음악 목록 요청")
    }
    
    /// 연결 상태 확인 (View에서 호출)
    var isConnected: Bool {
        communicationService.isReachable
    }
    
    /// 안전한 음악 목록 동기화 (연결 상태 확인 후 요청)
    func requestMusicListIfConnected() {
        guard isConnected else {
            print("⚠️ ViewModel: 워치 연결 안됨 - 동기화 건너뜀")
            return
        }
        requestMusicList()
    }
    
    // MARK: - Immediate Sync Methods
    
    /// 앞으로/뒤로 이동 후 즉시 iOS 상태 요청
    func requestImmediateSync() {
        print("🔄 워치: 즉시 상태 동기화 요청")
        DispatchQueue.main.async {
            self.communicationService.requestCurrentState()
        }
    }
    
    /// 빠른 연타 방지를 위한 debounce 동기화
    func requestSyncWithDebounce() {
        print("🔄 워치: debounce 동기화 요청")
        
        // 기존 타이머 취소
        debounceTimer?.invalidate()
        
        // 0.5초 후 동기화 (마지막 동작 후에만)
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.requestImmediateSync()
        }
    }
    
    // MARK: - Combined Playback Actions (View에서 호출)
    
    /// 뒤로 이동 + 동기화 조합 (View에서 호출)
    func performBackward() async {
        playBackward()
        requestSyncWithDebounce()
    }
    
    /// 앞으로 이동 + 동기화 조합 (View에서 호출)
    func performForward() async {
        playForward()
        requestSyncWithDebounce()
    }
    
    /// 재생 토글 + 동기화 조합 (View에서 호출)
    func performPlayToggle() async -> Bool {
        let wasPlaying = isPlaying
        playToggle()
        requestImmediateSync()
        return !wasPlaying
    }
    
    // MARK: - Private Properties
    
    /// debounce를 위한 타이머
    private var debounceTimer: Timer? {
        get {
            objc_getAssociatedObject(self, &debounceTimerKey) as? Timer
        }
        set {
            objc_setAssociatedObject(self, &debounceTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var debounceTimerKey: UInt8 = 0