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
    
    /// 현재 편집 중인 마커의 인덱스
    var editingIndex: Int? { get }
    
    /// 마커 편집 모드 활성화 상태
    var isEditing: Bool { get }
    
    // MARK: - 마커 관리 메서드 (async/await 버전)
    
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
    
    /// 마커를 편집합니다.
    /// - Parameters:
    ///   - index: 편집할 마커의 인덱스
    ///   - newTime: 새로운 마커 시간
    /// - Throws: 마커 편집 실패 시 `DancingMarkerError` 예외를 던짐
    func editMarker(at index: Int, to newTime: TimeInterval) async throws
    
    /// 마커 편집 모드를 시작합니다.
    /// - Parameter index: 편집할 마커의 인덱스
    func startEditing(at index: Int)
    
    /// 마커 편집 모드를 종료합니다.
    func stopEditing()
    
    /// 모든 마커를 초기화합니다.
    /// - Throws: 초기화 실패 시 `DancingMarkerError` 예외를 던짐
    func clearAllMarkers() async throws
    
    // MARK: - ✅ 누락된 메서드들 추가
    
    /// 편집 중인 마커의 변경사항을 저장합니다.
    /// - Throws: 저장 실패 시 `DancingMarkerError` 예외를 던짐
    func saveEditingMarker() async throws
    
    /// 마커 배열을 직접 설정합니다.
    /// - Parameter newMarkers: 새로운 마커 배열
    func setMarkers(_ newMarkers: [TimeInterval])
    
    /// 특정 인덱스의 마커가 유효한지 확인합니다.
    /// - Parameter index: 확인할 마커 인덱스
    /// - Returns: 마커가 유효하면 true, 그렇지 않으면 false
    func isValidMarker(at index: Int) -> Bool
    
    // MARK: - 마커 편집 시간 조정 메서드
    
    /// 편집 중인 마커의 시간을 1초 감소시킵니다.
    func decreaseEditingTime()
    
    /// 편집 중인 마커의 시간을 1초 증가시킵니다.
    /// - Parameter maxDuration: 최대 허용 시간 (음악 길이)
    func increaseEditingTime(maxDuration: TimeInterval)
    
    /// 현재 편집 중인 마커의 시간을 반환합니다.
    var currentEditingTime: TimeInterval? { get }
}
