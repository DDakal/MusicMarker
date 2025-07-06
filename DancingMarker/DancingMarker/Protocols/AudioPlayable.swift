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
    /// - Parameter fileURL: 재생할 음악 파일의 URL
    /// - Throws: 재생 실패 시 `DancingMarkerError` 예외를 던짐
    func playMusic(from fileURL: URL) async throws
    
    /// 재생을 일시 정지합니다.
    func pause()
    
    /// 재생을 재개합니다.
    func resume() async throws
    
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
    
    /// 볼륨을 설정합니다.
    /// - Parameter volume: 설정할 볼륨 (0.0 ~ 1.0)
    /// - Throws: 볼륨 설정 실패 시 `DancingMarkerError` 예외를 던짐
    func setVolume(_ volume: Float) async throws
    
    // MARK: - 추가 메서드
    
    /// 현재 재생 시간을 가져옵니다.
    /// - Returns: 현재 재생 시간 (초)
    /// - Throws: 시간 조회 실패 시 `DancingMarkerError` 예외를 던짐
    func getCurrentTime() async throws -> TimeInterval
}

// MARK: - Legacy Support (기존 Music 타입 지원)

extension AudioPlayable {
    /// 기존 Music 객체를 지원하는 확장 메서드
    /// - Parameter music: 재생할 음악 정보 (기존 호환성)
    /// - Throws: 재생 실패 시 `DancingMarkerError` 예외를 던짐
    func play(_ music: Music) async throws {
        try await playMusic(from: music.fileURL)
    }
}
