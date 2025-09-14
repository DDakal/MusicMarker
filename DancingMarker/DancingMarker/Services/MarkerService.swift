//
//  MarkerService.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI
import SwiftData

/// 마커 관리를 담당하는 서비스
///
/// MarkerManageable 프로토콜을 구현하여 음악의 특정 시간 지점을
/// 마커로 저장하고 관리하는 기능을 제공합니다.
final class MarkerService: MarkerManageable {
    
    // MARK: - Published Properties
    
    @Published private(set) var markers: [TimeInterval] = [-1, -1, -1]
    
    // MARK: - Private Properties
    
    private let formatter: DateComponentsFormatter
    
    // MARK: - Initialization
    
    init() {
        self.formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
    }
    
    // MARK: - MarkerManageable Protocol Implementation
    
    func addMarker(at time: TimeInterval, index: Int) async throws {
        // 인덱스 유효성 검사
        guard index >= 0 && index < 3 else {
            throw DancingMarkerError.markerInvalidIndex
        }
        
        // 시간 유효성 검사
        guard time >= 0 else {
            throw DancingMarkerError.markerInvalidTime
        }
        
        await MainActor.run {
            self.markers[index] = time
        }
        
    }
    
    func deleteMarker(at index: Int) async throws {
        // 인덱스 유효성 검사
        guard index >= 0 && index < 3 else {
            throw DancingMarkerError.markerInvalidIndex
        }
        
        // 마커 존재 여부 확인
        guard markers[index] != -1 else {
            throw DancingMarkerError.markerNotFound
        }
        
        await MainActor.run {
            self.markers[index] = -1
        }
        
    }
    
    func clearAllMarkers() async throws {
        await MainActor.run {
            self.markers = [-1, -1, -1]
        }
        
    }
    
    // MARK: - Additional Helper Methods
    
    /// 특정 인덱스의 마커가 유효한지 확인합니다.
    func isValidMarker(at index: Int) -> Bool {
        guard index >= 0 && index < 3 else { return false }
        return markers[index] != -1
    }
    
    /// 마커를 포맷된 시간 문자열로 반환합니다.
    func formattedMarker(at index: Int) -> String {
        guard index >= 0 && index < 3 else { return "99:59" }
        
        let marker = markers[index]
        if marker == -1 {
            return "99:59"
        }
        
        return formatter.string(from: marker) ?? "0:00"
    }
    
    /// 모든 마커를 포맷된 문자열 배열로 반환합니다.
    var formattedMarkers: [String] {
        return markers.enumerated().map { index, marker in
            if marker == -1 {
                return "99:59"
            }
            return formatter.string(from: marker) ?? "0:00"
        }
    }
    
    /// 유효한 마커의 개수를 반환합니다.
    var validMarkerCount: Int {
        return markers.filter { $0 != -1 }.count
    }
    
    /// 특정 마커로 이동할 수 있는지 확인합니다.
    func canMoveToMarker(at index: Int) -> Bool {
        return isValidMarker(at: index)
    }
    
    // MARK: - Integration Methods
    
    /// Music 객체의 마커들을 서비스에 로드합니다.
    func loadMarkers(from music: Music) {
        markers = music.markers
    }
    
    /// 현재 마커들을 Music 객체에 저장합니다.
    func saveMarkers(to music: Music) {
        music.markers = markers
    }
    
    /// 마커 배열을 직접 설정합니다 (워치 연동용)
    func setMarkers(_ newMarkers: [TimeInterval]) {
        guard newMarkers.count == 3 else { return }
        markers = newMarkers
    }
    
    /// 특정 인덱스에 현재 재생 시간을 마커로 저장합니다.
    func addCurrentTimeAsMarker(currentTime: TimeInterval, at index: Int) async throws {
        try await addMarker(at: currentTime, index: index)
    }
}
