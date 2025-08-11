//
//  WatchCommunicatable.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/6/25.
//

import Foundation

/// 워치와 iOS 간 통신을 담당하는 프로토콜
protocol WatchCommunicatable {
    
    // MARK: - Connection Status
    
    /// 현재 연결 상태
    var isReachable: Bool { get }
    
    // MARK: - Playback Control
    
    /// 재생/일시정지 토글
    func sendPlayToggle()
    
    /// 5초 앞으로 이동
    func sendForward()
    
    /// 5초 뒤로 이동
    func sendBackward()
    
    /// 재생 속도 증가
    func sendIncreasePlayback()
    
    /// 재생 속도 감소
    func sendDecreasePlayback()
    
    /// 재생 속도 원래대로
    func sendOriginalPlayback()
    
    // MARK: - Music Selection
    
    /// UUID로 음악 선택
    func sendMusicSelection(_ musicID: String)
    
    // MARK: - Marker Control
    
    /// 마커 재생
    func sendMarkerPlay(at index: Int)
    
    /// 마커 저장
    func sendMarkerSave(at index: Int)
    
    /// 마커 삭제
    func sendMarkerDelete(at index: Int)
    
    /// 마커 편집 완료
    func sendMarkerEditSuccess(index: Int, time: Int)
    
    // MARK: - Volume Control
    
    /// 볼륨 변경
    func sendVolumeChange(_ volume: Float)
    
    // MARK: - Sync Requests
    
    /// 음악 목록 요청
    func requestMusicList()
    
    /// 현재 상태 즉시 동기화 요청
    func requestCurrentState()
}
