//
//  WatchConnectivityManageable.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI

/// 워치와 iOS 간의 통신을 관리하는 프로토콜
///
/// Watch Connectivity Framework를 사용하여 Apple Watch와 iOS 앱 간의
/// 실시간 데이터 동기화를 제공합니다.
///
/// ## 주요 기능
/// - 재생 상태 동기화
/// - 마커 정보 동기화
/// - 음악 목록 동기화
/// - 제어 명령 전송
protocol WatchConnectivityManageable: ObservableObject {
    
    // MARK: - 연결 상태 프로퍼티
    
    /// 워치와의 연결 상태를 반환합니다.
    /// - Returns: 연결되어 있으면 `true`, 아니면 `false`
    var isConnected: Bool { get }
    
    /// 워치가 도달 가능한 상태인지 반환합니다.
    /// - Returns: 도달 가능하면 `true`, 아니면 `false`
    var isReachable: Bool { get }
    
    // MARK: - 데이터 전송 메서드
    
    /// 재생 상태를 워치로 전송합니다.
    ///
    /// 현재 재생 중인 음악의 상태 정보를 실시간으로 워치에 전달합니다.
    ///
    /// - Parameters:
    ///   - isPlaying: 재생 상태
    ///   - currentTime: 현재 재생 시간 (초)
    ///   - duration: 전체 재생 시간 (초)
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendPlayingState(
        isPlaying: Bool,
        currentTime: TimeInterval,
        duration: TimeInterval
    ) async throws
    
    /// 마커 정보를 워치로 전송합니다.
    /// - Parameter markers: 전송할 마커 배열
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendMarkers(_ markers: [TimeInterval]) async throws
    
    /// 음악 목록을 워치로 전송합니다.
    /// - Parameter musicList: 전송할 음악 목록
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendMusicList(_ musicList: [Music]) async throws
    
    /// 재생 속도를 워치로 전송합니다.
    /// - Parameter rate: 재생 속도 (0.5 ~ 1.5)
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendPlaybackRate(_ rate: Float) async throws
    
    /// 현재 재생 중인 음악 제목을 워치로 전송합니다.
    /// - Parameter title: 음악 제목
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendMusicTitle(_ title: String) async throws
    
    /// 시스템 볼륨을 워치로 전송합니다.
    /// - Parameter volume: 시스템 볼륨 (0.0 ~ 1.0)
    /// - Throws: 전송 실패 시 `DancingMarkerError` 예외를 던짐
    func sendSystemVolume(_ volume: Float) async throws
    
    // MARK: - 메시지 수신 처리
    
    /// 워치로부터 받은 메시지를 처리하는 델리게이트를 설정합니다.
    /// - Parameter delegate: 메시지 처리 델리게이트
    func setMessageDelegate(_ delegate: WatchMessageDelegate?)
    
    /// Watch Connectivity 세션을 활성화합니다.
    /// - Throws: 활성화 실패 시 `DancingMarkerError` 예외를 던짐
    func activateSession() async throws
    
    /// Watch Connectivity 세션을 비활성화합니다.
    func deactivateSession()
}

/// 워치로부터 받은 메시지를 처리하는 델리게이트 프로토콜
protocol WatchMessageDelegate: AnyObject {
    
    /// 재생/일시정지 토글 명령을 받았을 때 호출됩니다.
    nonisolated func didReceivePlayToggleCommand()
    
    /// 5초 앞으로 이동 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveForwardCommand()
    
    /// 5초 뒤로 이동 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveBackwardCommand()
    
    /// 재생 속도 증가 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveIncreaseSpeedCommand()
    
    /// 재생 속도 감소 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveDecreaseSpeedCommand()
    
    /// 원래 재생 속도로 복원 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveOriginalSpeedCommand()
    
    /// 마커 재생 명령을 받았을 때 호출됩니다.
    /// - Parameter index: 재생할 마커의 인덱스 (0, 1, 2)
    nonisolated func didReceiveMarkerPlayCommand(index: Int)
    
    /// 마커 저장 명령을 받았을 때 호출됩니다.
    /// - Parameter index: 저장할 마커의 인덱스 (0, 1, 2)
    nonisolated func didReceiveMarkerSaveCommand(index: Int)
    
    /// 마커 삭제 명령을 받았을 때 호출됩니다.
    /// - Parameter index: 삭제할 마커의 인덱스 (0, 1, 2)
    nonisolated func didReceiveMarkerDeleteCommand(index: Int)
    
    /// 마커 편집 명령을 받았을 때 호출됩니다.
    /// - Parameters:
    ///   - index: 편집할 마커의 인덱스
    ///   - adjustment: 시간 조정값 (초)
    nonisolated func didReceiveMarkerEditCommand(index: Int, adjustment: Double)
    
    /// 음악 선택 명령을 받았을 때 호출됩니다.
    /// - Parameter musicID: 선택된 음악의 UUID
    nonisolated func didReceiveMusicSelectionCommand(musicID: UUID)
    
    /// 볼륨 변경 명령을 받았을 때 호출됩니다.
    /// - Parameter volume: 설정할 볼륨 (0.0 ~ 1.0)
    nonisolated func didReceiveVolumeChangeCommand(volume: Float)
    
    /// 음악 목록 요청 명령을 받았을 때 호출됩니다.
    nonisolated func didReceiveMusicListRequestCommand()
}
