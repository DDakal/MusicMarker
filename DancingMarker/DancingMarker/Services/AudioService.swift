//
//  AudioService.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/4/25.
//

import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer

/// 오디오 재생을 담당하는 서비스
///
/// AudioPlayable 프로토콜을 구현하여 로컬 음악 파일의 재생, 일시정지,
/// 속도 조절 등의 기능을 제공합니다.
final class AudioService: AudioPlayable {
    
    // MARK: - Published Properties
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var playbackRate: Float = 1.0
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let formatter: DateComponentsFormatter
    
    // MARK: - Initialization
    
    init() {
        self.formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        
        setupAudioSession()
    }
    
    deinit {
        stopTimer()
        audioPlayer?.stop()
    }
    
    // MARK: - AudioPlayable Protocol Implementation
    
    /// 음악을 재생합니다 (새로운 URL 기반 메서드)
    func playMusic(from fileURL: URL) async throws {
        // 기존 재생 중단
        stop()
        
        // 파일 존재 여부 확인
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw DancingMarkerError.audioFileNotFound
        }
        
        do {
            // AVAudioPlayer 초기화
            self.audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            guard let player = audioPlayer else {
                throw DancingMarkerError.audioInitializationFailed
            }
            
            // 플레이어 설정
            player.prepareToPlay()
            player.enableRate = true
            player.numberOfLoops = -1 // 무한 반복
            player.rate = playbackRate
            
            // 재생 시작
            player.play()
            
            // 상태 업데이트
            await MainActor.run {
                self.isPlaying = true
                self.duration = player.duration
                self.startTimer()
            }
            
        } catch {
            throw DancingMarkerError.audioInitializationFailed
        }
    }
    
    /// 재생을 일시정지합니다
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    /// 재생을 재개합니다 (새로 추가된 메서드)
    func resume() async throws {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioInitializationFailed
        }
        
        player.play()
        
        await MainActor.run {
            self.isPlaying = true
            self.startTimer()
        }
    }
    
    /// 재생을 완전히 중지합니다
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    /// 재생 위치를 변경합니다
    func seek(to time: TimeInterval) async throws {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioSeekFailed
        }
        
        let seekTime = max(0, min(time, player.duration))
        player.currentTime = seekTime
        
        await MainActor.run {
            self.currentTime = seekTime
        }
    }
    
    /// 5초 뒤로 이동합니다
    func skipBackward() async throws {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioSeekFailed
        }
        
        let newTime = max(player.currentTime - 5, 0)
        try await seek(to: newTime)
    }
    
    /// 5초 앞으로 이동합니다
    func skipForward() async throws {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioSeekFailed
        }
        
        let newTime = min(player.currentTime + 5, player.duration)
        try await seek(to: newTime)
    }
    
    /// 재생 속도를 변경합니다
    func setPlaybackRate(_ rate: Float) async throws {
        guard rate >= 0.5 && rate <= 1.5 else {
            throw DancingMarkerError.audioInvalidPlaybackRate
        }
        
        audioPlayer?.rate = rate
        
        await MainActor.run {
            self.playbackRate = rate
        }
    }
    
    /// 볼륨을 설정합니다 (새로 추가된 메서드)
    func setVolume(_ volume: Float) async throws {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioInitializationFailed
        }
        
        let clampedVolume = max(0.0, min(1.0, volume))
        player.volume = clampedVolume
    }
    
    /// 현재 재생 시간을 가져옵니다 (새로 추가된 메서드)
    func getCurrentTime() async throws -> TimeInterval {
        guard let player = audioPlayer else {
            throw DancingMarkerError.audioInitializationFailed
        }
        
        return player.currentTime
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            
            Task { @MainActor in
                if !player.isPlaying {
                    self.isPlaying = false
                }
                self.currentTime = player.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Helper Methods
    
    /// 시간을 "분:초" 형식으로 포맷팅합니다.
    func formattedTime(_ time: TimeInterval) -> String {
        return formatter.string(from: time) ?? "0:00"
    }
    
    /// 현재 재생 진행률을 반환합니다 (0.0 ~ 1.0)
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}
