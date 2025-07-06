//
//  PlayerViewModel+Marker.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/21/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Marker Management

extension PlayerViewModel {
    
    // MARK: - Marker Actions (Public Interface)
    
    /// 현재 재생 시간에 마커를 추가합니다
    /// - Parameter index: 마커 인덱스 (0, 1, 2)
    func addMarkerAtCurrentTime(at index: Int) async {
        do {
            // MarkerService를 통해 마커 추가
            try await markerService.addMarker(at: currentTime, index: index)
            
            // PlayerViewModel의 마커 배열 동기화
            await updateMarkersFromService()
            
            // 현재 음악의 마커 업데이트
            try await updateCurrentMusicMarkers()
            
            // 워치에 마커 정보 전송 (PlayerViewModel+Watch.swift의 메서드 사용)
            await sendMarkersToWatch()
            
            print("마커 \(index + 1) 추가됨: \(formattedTime(currentTime))")
            
        } catch {
            print("마커 추가 실패: \(error)")
        }
    }
    
    /// 특정 마커로 이동합니다
    /// - Parameter index: 마커 인덱스
    func moveToMarker(at index: Int) async {
        // ✅ 이미 마커 이동 중이면 무시
        guard !isMarkerSeeking else {
            print("⚠️ 이미 마커 이동 중 - 요청 무시")
            return
        }
        
        do {
            guard markerService.isValidMarker(at: index) else {
                print("유효하지 않은 마커: \(index)")
                return
            }
            
            let markerTime = markers[index]
            
            // ✅ 마커 이동 시작 - AudioService 동기화 중단
            setMarkerSeeking(true)
            
            // AudioService를 통해 시간 이동 (순수한 seek만)
            try await audioService.seek(to: markerTime)
            
            // ✅ seek 후 즉시 강제 동기화
            await forceSyncAfterSeek()
            
            // ✅ 0.5초 후 마커 이동 완료 (짧은 안정화 시간)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                await MainActor.run {
                    self.setMarkerSeeking(false)
                    
                    // 마커 이동 완료 후 외부 서비스 상태 전송
                    Task {
                        await self.sendCompleteStateToExternalServices()
                    }
                }
            }
            
            print("마커 \(index + 1)로 이동: \(formattedTime(markerTime))")
            
        } catch {
            print("마커 이동 실패: \(error)")
            setMarkerSeeking(false)
        }
    }
    
    /// 마커를 삭제합니다
    /// - Parameter index: 마커 인덱스
    func deleteMarker(at index: Int) async {
        do {
            try await markerService.deleteMarker(at: index)
            
            // PlayerViewModel의 마커 배열 동기화
            await updateMarkersFromService()
            
            // 현재 음악의 마커 업데이트
            try await updateCurrentMusicMarkers()
            
            // 워치에 마커 정보 전송
            await sendMarkersToWatch()
            
            print("마커 \(index + 1) 삭제됨")
            
        } catch {
            print("마커 삭제 실패: \(error)")
        }
    }
    
    /// 마커를 편집합니다
    /// - Parameters:
    ///   - index: 마커 인덱스
    ///   - newTime: 새로운 시간
    func editMarker(at index: Int, to newTime: TimeInterval) async {
        do {
            try await markerService.editMarker(at: index, to: newTime)
            
            // PlayerViewModel의 마커 배열 동기화
            await updateMarkersFromService()
            
            // 현재 음악의 마커 업데이트
            try await updateCurrentMusicMarkers()
            
            // 워치에 마커 정보 전송
            await sendMarkersToWatch()
            
            print("마커 \(index + 1) 편집됨: \(formattedTime(newTime))")
            
        } catch {
            print("마커 편집 실패: \(error)")
        }
    }
    
    /// 모든 마커를 초기화합니다
    func clearAllMarkers() async {
        do {
            try await markerService.clearAllMarkers()
            
            // PlayerViewModel의 마커 배열 동기화
            await updateMarkersFromService()
            
            // 현재 음악의 마커 업데이트
            try await updateCurrentMusicMarkers()
            
            // 워치에 마커 정보 전송
            await sendMarkersToWatch()
            
            print("모든 마커 초기화됨")
            
        } catch {
            print("마커 초기화 실패: \(error)")
        }
    }
    
    // MARK: - Marker Editing Support
    
    /// 마커 편집 모드를 시작합니다
    /// - Parameter index: 편집할 마커 인덱스
    func startMarkerEditing(at index: Int) {
        markerService.startEditing(at: index)
        isEditingMarker = true
        editingMarkerIndex = index
        
        print("마커 \(index + 1) 편집 모드 시작")
    }
    
    /// 마커 편집 모드를 종료합니다
    func stopMarkerEditing() {
        markerService.stopEditing()
        isEditingMarker = false
        editingMarkerIndex = nil
        
        print("마커 편집 모드 종료")
    }
    
    /// 편집 중인 마커를 저장합니다
    func saveEditingMarker() async {
        do {
            // ✅ MarkerService의 실제 메서드 사용
            try await markerService.saveEditingMarker()
            
            // 편집 모드 종료
            stopMarkerEditing()
            
            // PlayerViewModel의 마커 배열 동기화
            await updateMarkersFromService()
            
            // 현재 음악의 마커 업데이트
            try await updateCurrentMusicMarkers()
            
            // 워치에 마커 정보 전송
            await sendMarkersToWatch()
            
            print("편집 중인 마커 저장됨")
            
        } catch {
            print("편집 마커 저장 실패: \(error)")
        }
    }
    
    // MARK: - UI Helper Methods (PlayingView에서 사용)
    
    /// 편집 중인 마커의 시간을 1초 감소시킵니다 (유효성 검사 포함)
    func decreaseEditingMarkerTime() {
        guard canDecreaseEditingMarker else {
            print("⚠️ 마커 편집 시간을 더 이상 감소시킬 수 없습니다")
            return
        }
        
        markerService.decreaseEditingTime()
        print("마커 편집 시간 1초 감소: \(formattedTime(currentEditingTime ?? 0))")
    }
    
    /// 편집 중인 마커의 시간을 1초 증가시킵니다 (유효성 검사 포함)
    func increaseEditingMarkerTime() {
        guard canIncreaseEditingMarker else {
            print("⚠️ 마커 편집 시간을 더 이상 증가시킬 수 없습니다")
            return
        }
        
        markerService.increaseEditingTime(maxDuration: duration)
        print("마커 편집 시간 1초 증가: \(formattedTime(currentEditingTime ?? 0))")
    }
    
    /// 편집 중인 마커의 현재 시간을 반환합니다
    var currentEditingTime: TimeInterval? {
        return markerService.currentEditingTime
    }
    
    // MARK: - Marker Editing Validation (Computed Properties)
    
    /// 마커 편집 시간을 감소시킬 수 있는지 확인
    var canDecreaseEditingMarker: Bool {
        guard let currentEditingTime = currentEditingTime else {
            return false
        }
        // 1초 이상일 때만 감소 가능
        return currentEditingTime > 1.0
    }
    
    /// 마커 편집 시간을 증가시킬 수 있는지 확인
    var canIncreaseEditingMarker: Bool {
        guard let currentEditingTime = currentEditingTime else {
            return false
        }
        // duration-1초 미만일 때만 증가 가능
        return currentEditingTime < (duration - 1.0)
    }
    
    // MARK: - Notification Handlers (워치에서 호출)
    
    /// 워치에서 마커 재생 요청 처리
    internal func handleMarkerPlay(at index: Int) async {
        guard index >= 0 && index < 3 else {
            print("잘못된 마커 인덱스: \(index)")
            return
        }
        
        await moveToMarker(at: index)
    }
    
    /// 워치에서 마커 저장 요청 처리
    internal func handleMarkerSave(at index: Int) async {
        guard index >= 0 && index < 3 else {
            print("잘못된 마커 인덱스: \(index)")
            return
        }
        
        await addMarkerAtCurrentTime(at: index)
    }
    
    /// 워치에서 마커 삭제 요청 처리
    internal func handleMarkerDelete(at index: Int) async {
        guard index >= 0 && index < 3 else {
            print("잘못된 마커 인덱스: \(index)")
            return
        }
        
        await deleteMarker(at: index)
    }
    
    /// 워치에서 마커 편집 요청 처리
    internal func handleMarkerEdit(at index: Int, adjustment: Double) async {
        guard index >= 0 && index < 3 else {
            print("잘못된 마커 인덱스: \(index)")
            return
        }
        
        guard markers[index] != -1 else {
            print("편집할 마커가 존재하지 않음: \(index)")
            return
        }
        
        let newTime = markers[index] + adjustment
        await editMarker(at: index, to: max(0, newTime))
    }
}

// MARK: - Private Helper Methods

private extension PlayerViewModel {
    
    /// MarkerService의 마커 상태를 PlayerViewModel과 동기화합니다
    func updateMarkersFromService() async {
        await MainActor.run {
            self.markers = markerService.markers
        }
    }
    
    /// 현재 음악의 마커 정보를 업데이트하고 데이터베이스에 저장합니다
    func updateCurrentMusicMarkers() async throws {
        guard var currentMusic = self.currentMusic else { return }
        
        // 1. MusicData 업데이트
        currentMusic.markers = markers
        self.currentMusic = currentMusic
        
        // 2. 데이터베이스의 실제 Music 객체 찾기 및 업데이트
        let musicId = currentMusic.id  // 값을 미리 추출
        let predicate = #Predicate<Music> { music in
            music.id == musicId  // 같은 타입끼리 비교
        }
        
        let descriptor = FetchDescriptor<Music>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            if let music = results.first {
                music.markers = markers
                try modelContext.save()
                print("마커 데이터베이스 저장 완료: \(music.title)")
            }
        } catch {
            print("마커 데이터베이스 저장 실패: \(error)")
            throw error
        }
    }
    
    /// 외부 서비스들에게 현재 상태를 전송합니다 (마커 관련)
    func sendCurrentStateToExternalServices() async {
        // 워치에 재생 상태 전송
        do {
            try await watchService.sendPlayingState(
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
        } catch {
            print("워치 재생 상태 전송 실패: \(error)")
        }
        
        // Control Center 업데이트
        guard let music = currentMusic else { return }
        
        do {
            let nowPlayingInfo = NowPlayingInfo(
                title: music.title,
                artist: music.artist,
                currentTime: currentTime,
                duration: duration,
                isPlaying: isPlaying,
                playbackRate: playbackRate,
                albumArtData: music.albumArt
            )
            
            try await liveActivityService.updateNowPlayingInfo(nowPlayingInfo)
        } catch {
            print("Control Center 업데이트 실패: \(error)")
        }
    }
    
    /// 마커 이동 후 완전 동기화 (새로 추가)
    private func forceSyncAfterMarkerMove() async {
        do {
            // AudioService에서 최신 상태 강제 가져오기
            let audioCurrentTime = try await audioService.getCurrentTime()
            let audioIsPlaying = audioService.isPlaying
            let audioDuration = audioService.duration
            let audioPlaybackRate = audioService.playbackRate
            
            // 모든 상태 즉시 동기화
            currentTime = audioCurrentTime
            isPlaying = audioIsPlaying
            duration = audioDuration
            playbackRate = audioPlaybackRate
            
            // UI 관련 계산값 즉시 업데이트
            updateProgress()
            updateFormattedTime()
            
            if formattedDuration != formattedTime(duration) {
                formattedDuration = formattedTime(duration)
            }
            
            print("마커 이동 후 강제 동기화 완료: 재생상태=\(isPlaying), 시간=\(formattedTime(currentTime))")
            
        } catch {
            print("마커 이동 후 동기화 실패: \(error)")
        }
    }
    
    /// 외부 서비스들에 완전한 상태를 전송합니다
    private func sendCompleteStateToExternalServices() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.sendPlayingStateToWatch() }
            group.addTask { await self.updateControlCenterNowPlaying() }
            group.addTask { await self.notifyControlCenterOfMarkerJump() }
        }
        print("✅ 마커 이동 완료 후 모든 외부 서비스 상태 동기화 완료")
    }
}

// MARK: - Music Loading Support

extension PlayerViewModel {
    
    /// 새로운 음악의 마커들을 로드합니다
    /// - Parameter musicData: 음악 데이터
    func loadMarkers(from musicData: MusicData) {
        // ✅ 이제 MarkerManageable 프로토콜에 setMarkers가 있음
        markerService.setMarkers(musicData.markers)
        
        // PlayerViewModel의 마커 배열 동기화
        markers = musicData.markers
        
        print("음악 마커 로드됨: \(musicData.title)")
        print("마커 정보: \(markers)")
    }
}

// MARK: - Computed Properties for UI

extension PlayerViewModel {
    
    /// 포맷된 마커 시간들을 반환합니다 (UI 표시용)
    var formattedMarkers: [String] {
        return markers.map { marker in
            if marker == -1 {
                return "99:59"
            }
            return formattedTime(marker)
        }
    }
    
    /// 유효한 마커의 개수를 반환합니다
    var validMarkerCount: Int {
        return markers.filter { $0 != -1 }.count
    }
    
    /// 특정 인덱스의 마커가 유효한지 확인합니다
    func isValidMarker(at index: Int) -> Bool {
        guard index >= 0 && index < 3 else { return false }
        return markers[index] != -1
    }
}
