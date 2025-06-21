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
    @Published private(set) var editingIndex: Int? = nil
    @Published private(set) var isEditing: Bool = false
    
    // MARK: - Private Properties
    
    private var editingMarker: TimeInterval = 0.0
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
        
        // SwiftData 저장 로직은 나중에 추가
        // TODO: modelContext.save()
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
        
        // SwiftData 저장 로직은 나중에 추가
        // TODO: modelContext.save()
    }
    
    func editMarker(at index: Int, to newTime: TimeInterval) async throws {
        // 인덱스 유효성 검사
        guard index >= 0 && index < 3 else {
            throw DancingMarkerError.markerInvalidIndex
        }
        
        // 마커 존재 여부 확인
        guard markers[index] != -1 else {
            throw DancingMarkerError.markerNotFound
        }
        
        // 시간 유효성 검사
        guard newTime >= 0 else {
            throw DancingMarkerError.markerInvalidTime
        }
        
        await MainActor.run {
            self.markers[index] = newTime
        }
        
        // SwiftData 저장 로직은 나중에 추가
        // TODO: modelContext.save()
    }
    
    func startEditing(at index: Int) {
        guard index >= 0 && index < 3 else { return }
        guard markers[index] != -1 else { return }
        
        isEditing = true
        editingIndex = index
        editingMarker = markers[index]
    }
    
    func stopEditing() {
        isEditing = false
        editingIndex = nil
        editingMarker = 0.0
    }
    
    func clearAllMarkers() async throws {
        await MainActor.run {
            self.markers = [-1, -1, -1]
        }
        
        // SwiftData 저장 로직은 나중에 추가
        // TODO: modelContext.save()
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
    
    // MARK: - Editing Support Methods
    
    /// 현재 편집 중인 마커의 시간을 반환합니다.
    var currentEditingTime: TimeInterval? {
        guard isEditing else { return nil }
        return editingMarker
    }
    
    /// 편집 중인 마커의 시간을 1초씩 증가시킵니다.
    func increaseEditingTime(maxDuration: TimeInterval) {
        guard isEditing else { return }
        
        if editingMarker < maxDuration - 1 {
            editingMarker += 1
        }
    }
    
    /// 편집 중인 마커의 시간을 1초씩 감소시킵니다.
    func decreaseEditingTime() {
        guard isEditing else { return }
        
        if editingMarker > 1 {
            editingMarker -= 1
        }
    }
    
    /// 편집 중인 마커의 변경사항을 저장합니다.
    func saveEditingMarker() async throws {
        guard let index = editingIndex else {
            throw DancingMarkerError.markerNotFound
        }
        
        try await editMarker(at: index, to: editingMarker)
        stopEditing()
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

// MARK: - Extensions

extension MarkerService {
    
    /// 마커 정보를 디버깅용 문자열로 반환합니다.
    var debugDescription: String {
        let markerStrings = markers.enumerated().map { index, marker in
            let timeString = marker == -1 ? "Empty" : formatter.string(from: marker) ?? "Invalid"
            return "Marker \(index): \(timeString)"
        }
        
        return """
        MarkerService Debug Info:
        \(markerStrings.joined(separator: "\n"))
        Editing: \(isEditing)
        Editing Index: \(editingIndex?.description ?? "None")
        Valid Markers: \(validMarkerCount)
        """
    }
}
