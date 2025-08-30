//
//  PlayerViewModel+Timer.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/13/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Timer Management

extension PlayerViewModel {
    
    /// AudioService의 @Published 프로퍼티를 직접 구독하여 상태 동기화
    internal func setupAudioServiceSubscription() {
        // AudioService를 AnyObject로 캐스팅하여 구독
        guard let audioServiceObject = audioService as? AudioService else {
            print("❌ AudioService를 구체 타입으로 캐스팅 실패")
            return
        }
        
        // isPlaying 변경 구독
        audioServiceObject.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsPlaying in
                Task { @MainActor in
                    await self?.handleAudioServicePlayingStateChange(newIsPlaying)
                }
            }
            .store(in: &cancellables)
        
        // currentTime 변경 구독
        audioServiceObject.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCurrentTime in
                Task { @MainActor in
                    await self?.handleAudioServiceTimeChange(newCurrentTime)
                }
            }
            .store(in: &cancellables)
        
        // duration 변경 구독
        audioServiceObject.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDuration in
                Task { @MainActor in
                    await self?.handleAudioServiceDurationChange(newDuration)
                }
            }
            .store(in: &cancellables)

        audioServiceObject.$playbackRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPlaybackRate in
                Task { @MainActor in
                    await self?.handleAudioServicePlaybackRateChange(newPlaybackRate)
                }
            }
            .store(in: &cancellables)
    }
    
    /// AudioService의 재생 상태 변경 처리
    @MainActor
    private func handleAudioServicePlayingStateChange(_ newIsPlaying: Bool) async {
        // 마커 이동 중이거나 드래그 중일 때는 상태 변경 제한
        guard !isMarkerSeeking && !isDragging else {
            print("🔄 재생 상태 변경 무시 (마커 이동 중: \(isMarkerSeeking), 드래그 중: \(isDragging))")
            return
        }
        
        let wasPlaying = isPlaying
        isPlaying = newIsPlaying
        
        // 재생 상태가 실제로 변경된 경우에만 외부 서비스 업데이트
        if wasPlaying != isPlaying {
            await sendPlayingStateToWatch()
            await updateControlCenterNowPlaying()
            print("✅ 재생 상태 변경 동기화 완료: \(isPlaying)")
        }
    }
    
    /// AudioService의 시간 변경 처리
    @MainActor
    private func handleAudioServiceTimeChange(_ newCurrentTime: TimeInterval) async {
        // 드래그 중일 때는 시간 업데이트 무시
        guard !isDragging else {
            return
        }
        
        currentTime = newCurrentTime
        updateProgress()
        updateFormattedTime()
        
        // 10초마다 Control Center 업데이트 (성능 최적화)
        if Int(currentTime) % 10 == 0 && !isControlCenterSeeking {
            await updateControlCenterPlaybackTime()
        }
        
        // 5초마다 워치 실시간 업데이트 (성능 최적화)
        if Int(currentTime) % 5 == 0 && !isMarkerSeeking {
            await sendRealTimeUpdateToWatch()
        }
    }
    
    /// AudioService의 duration 변경 처리
    @MainActor
    private func handleAudioServiceDurationChange(_ newDuration: TimeInterval) async {
        duration = newDuration
        
        if formattedDuration != formattedTime(duration) {
            formattedDuration = formattedTime(duration)
        }
    }

    /// AudioService의 재생 속도 변경 처리 (새로 추가)
    @MainActor
    private func handleAudioServicePlaybackRateChange(_ newPlaybackRate: Float) async {
        playbackRate = newPlaybackRate
        print("✅ 재생 속도 동기화 완료: \(newPlaybackRate)x")
    }
    
    /// 마커 이동 상태를 설정합니다
    func setMarkerSeeking(_ seeking: Bool) {
        isMarkerSeeking = seeking
        if seeking {
            print("🎯 마커 이동 시작 - AudioService 동기화 일시 중단")
        } else {
            print("✅ 마커 이동 완료 - AudioService 동기화 재개")
            // 마커 이동 완료 후 즉시 동기화
            Task {
                await forceSyncAfterSeek()
            }
        }
    }
    
    /// 슬라이더 드래그 상태를 설정합니다
    public func setDragging(_ isDragging: Bool) {
        self.isDragging = isDragging
        
        if !isDragging {
            // 드래그 종료 시 즉시 동기화
            Task {
                // 0.1초 대기 후 동기화 (seek 완료 대기)
                try? await Task.sleep(nanoseconds: 100_000_000)
                await forceSyncAfterSeek()
            }
        }
    }
    
    /// 강제 동기화 (seek 후 사용)
    public func forceSyncAfterSeek() async {
        do {
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
            
            print("강제 동기화 완료: \(formattedTime(currentTime))")
            
        } catch {
            print("강제 동기화 실패: \(error)")
        }
    }
}
