//
//  AudioPlayable.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI

/// 오디오 재생을 관리하는 프로토콜
protocol AudioPlayable: ObservableObject {
    
    // MARK: - 재생 상태 프로퍼티
    
    /// 현재 재생 중인 음악의 재생 상태
    var isPlaying: Bool { get }
    
    /// 현재 재생 시간 (초 단위)
    var currentTime: TimeInterval { get }
    
    /// 전체 재생 시간 (초 단위)
    var duration: TimeInterval { get }
    
    /// 재생 속도 (0.5 ~ 1.5 범위)
    var playbackRate: Float { get }
    
    // MARK: - 재생 제어 메서드 (async/await 버전)
    
    /// 음악을 재생합니다.
    /// - Parameter music: 재생할 음악 정보
    /// - Throws: 재생 실패 시 `DancingMarkerError` 예외를 던짐
    func play(_ music: Music) async throws
    
    /// 재생을 일시 정지합니다.
    func pause()
    
    /// 재생을 완전히 중지합니다.
    func stop()
    
    /// 재생 위치를 변경합니다.
    /// - Parameter time: 이동할 시간 (초 단위)
    /// - Throws: 이동 실패 시 `DancingMarkerError` 예외를 던짐
    func seek(to time: TimeInterval) async throws
    
    /// 현재 위치에서 5초 뒤로 이동합니다.
    /// - Throws: 이동 실패 시 `DancingMarkerError` 예외를 던짐
    func skipBackward() async throws
    
    /// 현재 위치에서 5초 앞으로 이동합니다.
    /// - Throws: 이동 실패 시 `DancingMarkerError` 예외를 던짐
    func skipForward() async throws
    
    /// 재생 속도를 변경합니다.
    /// - Parameter rate: 설정할 재생 속도 (0.5 ~ 1.5 범위)
    /// - Throws: 속도 변경 실패 시 `DancingMarkerError` 예외를 던짐
    func setPlaybackRate(_ rate: Float) async throws
}
