//
//  ControlCenterManageable.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI
import MediaPlayer

/// Control Center 및 Lock Screen 재생 정보를 관리하는 프로토콜
///
/// iOS의 Live Activity, Control Center, Lock Screen에
/// 나타나는 재생 정보와 컨트롤을 관리합니다.
///
/// ## 주요 기능
/// - Now Playing Info 업데이트
/// - Remote Control 이벤트 처리
/// - 앨범 아트 표시
/// - 백그라운드 재생 지원
protocol ControlCenterManageable: ObservableObject {
    
    // MARK: - Now Playing 정보 관리
    
    /// Control Center의 재생 정보를 업데이트합니다.
    ///
    /// 현재 재생 중인 음악의 정보를 Control Center, Lock Screen에 표시합니다.
    ///
    /// - Parameter info: 표시할 재생 정보
    /// - Throws: 업데이트 실패 시 `DancingMarkerError` 예외를 던짐
    func updateNowPlayingInfo(_ info: NowPlayingInfo) async throws
    
    /// Control Center의 모든 재생 정보를 초기화합니다.
    /// - Throws: 초기화 실패 시 `DancingMarkerError` 예외를 던짐
    func clearNowPlayingInfo() async throws
    
    // MARK: - Remote Control 설정
    
    /// Remote Control 명령을 처리하는 핸들러를 설정합니다.
    ///
    /// Control Center, Lock Screen, 헤드폰 버튼 등에서 발생하는
    /// 재생 제어 명령을 처리할 핸들러를 등록합니다.
    ///
    /// - Parameter handler: Remote Control 이벤트 처리 핸들러
    /// - Throws: 설정 실패 시 `DancingMarkerError` 예외를 던짐
    func setupRemoteControlHandlers(_ handler: RemoteControlHandler) async throws
    
    /// Remote Control 명령 수신을 비활성화합니다.
    func disableRemoteControlHandlers()
    
    // MARK: - 백그라운드 재생 설정
    
    /// 백그라운드 재생을 위한 오디오 세션을 구성합니다.
    ///
    /// 앱이 백그라운드로 이동해도 음악 재생이 계속되도록
    /// 오디오 세션을 설정합니다.
    ///
    /// - Throws: 구성 실패 시 `DancingMarkerError` 예외를 던짐
    func configureAudioSession() async throws
    
    /// 오디오 세션을 비활성화합니다.
    /// - Throws: 비활성화 실패 시 `DancingMarkerError` 예외를 던짐
    func deactivateAudioSession() async throws
    
    // MARK: - 앨범 아트 관리
    
    /// 기본 앨범 아트를 생성합니다.
    ///
    /// 앨범 아트가 없는 음악의 경우 기본 이미지를 생성하여 반환합니다.
    ///
    /// - Returns: 기본 앨범 아트 이미지 데이터
    func generateDefaultAlbumArt() -> Data?
    
    /// 앨범 아트 이미지를 처리합니다.
    /// - Parameters:
    ///   - imageData: 원본 이미지 데이터
    ///   - size: 목표 크기
    /// - Returns: 처리된 이미지 데이터
    /// - Throws: 이미지 처리 실패 시 `DancingMarkerError` 예외를 던짐
    func processAlbumArt(_ imageData: Data, targetSize size: CGSize) async throws -> Data
}

/// Now Playing 정보를 담는 구조체
struct NowPlayingInfo {
    /// 음악 제목
    let title: String
    
    /// 아티스트 이름
    let artist: String
    
    /// 현재 재생 시간 (초)
    let currentTime: TimeInterval
    
    /// 전체 재생 시간 (초)
    let duration: TimeInterval
    
    /// 재생 상태
    let isPlaying: Bool
    
    /// 재생 속도
    let playbackRate: Float
    
    /// 앨범 아트 이미지 데이터 (선택사항)
    let albumArtData: Data?
    
    /// 기본 이니셜라이저
    /// - Parameters:
    ///   - title: 음악 제목
    ///   - artist: 아티스트 이름
    ///   - currentTime: 현재 재생 시간
    ///   - duration: 전체 재생 시간
    ///   - isPlaying: 재생 상태
    ///   - playbackRate: 재생 속도 (기본값: 1.0)
    ///   - albumArtData: 앨범 아트 데이터 (기본값: nil)
    init(
        title: String,
        artist: String,
        currentTime: TimeInterval,
        duration: TimeInterval,
        isPlaying: Bool,
        playbackRate: Float = 1.0,
        albumArtData: Data? = nil
    ) {
        self.title = title
        self.artist = artist
        self.currentTime = currentTime
        self.duration = duration
        self.isPlaying = isPlaying
        self.playbackRate = playbackRate
        self.albumArtData = albumArtData
    }
}

/// Remote Control 이벤트를 처리하는 핸들러 프로토콜
protocol RemoteControlHandler: AnyObject {
    
    /// 재생/일시정지 토글 명령을 받았을 때 호출됩니다.
    func handlePlayPauseCommand()
    
    /// 5초 뒤로 이동 명령을 받았을 때 호출됩니다.
    func handleSkipBackwardCommand()
    
    /// 5초 앞으로 이동 명령을 받았을 때 호출됩니다.
    func handleSkipForwardCommand()
    
    /// 재생 위치 변경 명령을 받았을 때 호출됩니다.
    /// - Parameter position: 이동할 재생 위치 (초)
    func handleChangePlaybackPositionCommand(to position: TimeInterval)
    
    /// 다음 트랙 명령을 받았을 때 호출됩니다. (선택사항)
    func handleNextTrackCommand()
    
    /// 이전 트랙 명령을 받았을 때 호출됩니다. (선택사항)
    func handlePreviousTrackCommand()
}
