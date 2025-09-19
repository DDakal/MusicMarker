//
//  MarkerManageable.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI

/// 마커 관리를 담당하는 프로토콜
protocol MarkerManageable: ObservableObject {
    
    // MARK: - 마커 상태 프로퍼티
    
    /// 현재 음악의 모든 마커 (최대 3개, 빈 마커는 -1로 표시)
    var markers: [TimeInterval] { get }
    
    /// 새로운 마커를 추가합니다.
    /// - Parameters:
    ///   - time: 마커 시간 (초 단위)
    ///   - index: 마커 인덱스 (0, 1, 2 중 하나)
    /// - Throws: 마커 추가 실패 시 `DancingMarkerError` 예외를 던짐
    func addMarker(at time: TimeInterval, index: Int) async throws
    
    /// 마커를 삭제합니다.
    /// - Parameter index: 삭제할 마커의 인덱스
    /// - Throws: 마커 삭제 실패 시 `DancingMarkerError` 예외를 던짐
    func deleteMarker(at index: Int) async throws
    
    /// 모든 마커를 초기화합니다.
    /// - Throws: 초기화 실패 시 `DancingMarkerError` 예외를 던짐
    func clearAllMarkers() async throws
    
    /// 마커 배열을 직접 설정합니다.
    /// - Parameter newMarkers: 새로운 마커 배열
    func setMarkers(_ newMarkers: [TimeInterval])
    
    /// 특정 인덱스의 마커가 유효한지 확인합니다.
    /// - Parameter index: 확인할 마커 인덱스
    /// - Returns: 마커가 유효하면 true, 그렇지 않으면 false
    func isValidMarker(at index: Int) -> Bool
    
}
