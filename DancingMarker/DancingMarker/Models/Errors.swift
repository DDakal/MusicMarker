//
//  Errors.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation

/// 앱 전체에서 사용하는 에러 타입
enum DancingMarkerError: Error, LocalizedError {
    
    // MARK: - Audio 관련 에러
    case audioFileNotFound
    case audioInitializationFailed
    case audioSeekFailed
    case audioInvalidPlaybackRate
    
    // MARK: - Marker 관련 에러
    case markerInvalidIndex
    case markerInvalidTime
    case markerSaveFailed
    case markerNotFound
    
    // MARK: - Watch 관련 에러
    case watchNotConnected
    case watchSendFailed
    case watchNotSupported
    
    // MARK: - Control Center 관련 에러
    case controlCenterUpdateFailed
    case audioSessionSetupFailed
    
    // MARK: - 일반 에러
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .audioFileNotFound:
            return "음악 파일을 찾을 수 없습니다."
        case .audioInitializationFailed:
            return "오디오 플레이어 초기화에 실패했습니다."
        case .audioSeekFailed:
            return "재생 위치를 변경할 수 없습니다."
        case .audioInvalidPlaybackRate:
            return "유효하지 않은 재생 속도입니다."
        case .markerInvalidIndex:
            return "유효하지 않은 마커 위치입니다."
        case .markerInvalidTime:
            return "유효하지 않은 마커 시간입니다."
        case .markerSaveFailed:
            return "마커 저장에 실패했습니다."
        case .markerNotFound:
            return "마커를 찾을 수 없습니다."
        case .watchNotConnected:
            return "Apple Watch가 연결되지 않았습니다."
        case .watchSendFailed:
            return "Apple Watch로 데이터 전송에 실패했습니다."
        case .watchNotSupported:
            return "이 기기에서는 Apple Watch를 지원하지 않습니다."
        case .controlCenterUpdateFailed:
            return "재생 정보 업데이트에 실패했습니다."
        case .audioSessionSetupFailed:
            return "오디오 세션 설정에 실패했습니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
