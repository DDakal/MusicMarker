//
//  PlayerViewModel+Watch.swift
//  DancingMarker
//
//  Created by Woowon Kang on 6/21/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Watch Communication

extension PlayerViewModel {
    
    // MARK: - Watch Data Transmission
    
    /// 워치에 현재 재생 상태를 전송합니다
    func sendPlayingStateToWatch() async {
        print("🎯 iOS: sendPlayingStateToWatch 시작")
        print("   - isPlaying: \(isPlaying)")
        print("   - currentTime: \(currentTime)")
        print("   - duration: \(duration)")
        print("   - watchService.isConnected: \(watchService.isConnected)")
        print("   - watchService.isReachable: \(watchService.isReachable)")
        
        do {
            try await watchService.sendPlayingState(
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration
            )
            print("✅ iOS: 워치에 재생 상태 전송 완료")
        } catch {
            print("❌ iOS: 워치 재생 상태 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// 워치에 마커 정보를 전송합니다
    func sendMarkersToWatch() async {
        do {
            try await watchService.sendMarkers(markers)
            print("워치에 마커 정보 전송 완료")
        } catch {
            print("워치 마커 정보 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// SwiftData에서 최신 음악 목록을 로드하여 musicList 동기화
    func loadMusicListFromSwiftData() async {
        do {
            let descriptor = FetchDescriptor<Music>()
            let swiftDataMusicList = try modelContext.fetch(descriptor)
            
            // SwiftData의 Music을 MusicData로 변환
            let musicDataList = swiftDataMusicList.map { music in
                MusicData(
                    id: music.id,
                    title: music.title,
                    artist: music.artist,
                    fileName: music.fileName,
                    markers: music.markers,
                    albumArt: music.albumArt
                )
            }
            
            // PlayerViewModel.musicList 업데이트
            self.musicList = musicDataList
            print("✅ PlayerViewModel.musicList 동기화 완료: \(musicDataList.count)개")
            
        } catch {
            print("❌ SwiftData에서 음악 목록 로드 실패: \(error)")
        }
    }
    
    /// 워치에 음악 목록을 전송합니다 - 3단계 동기화 시스템 사용
    func sendMusicListToWatch() async {
        print("🎯 sendMusicListToWatch 시작")
        
        // 먼저 SwiftData에서 최신 음악 목록 로드
        await loadMusicListFromSwiftData()
        
        print("   - 전송할 음악 개수: \(musicList.count)")
        
        // MusicData를 [[String]] 형태로 변환 (워치에서 기대하는 형태)
        let musicListForWatch = self.musicList.map { musicData in
            return [musicData.title, musicData.id.uuidString]
        }
        
        // ✅ 3단계 동기화 시스템 사용
        WatchConnectivityManager.shared.syncMusicDataToWatch(musicListForWatch)
        
        print("✅ 3단계 동기화로 음악 목록 전송 완료")
    }
    
    /// 워치에 현재 음악 제목을 전송합니다
    func sendMusicTitleToWatch() async {
        guard let currentMusic = self.currentMusic else { return }
        
        do {
            try await watchService.sendMusicTitle(currentMusic.title)
            print("워치에 음악 제목 전송 완료: \(currentMusic.title)")
        } catch {
            print("워치 음악 제목 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// 워치에 재생 속도를 전송합니다
    func sendPlaybackRateToWatch() async {
        do {
            try await watchService.sendPlaybackRate(playbackRate)
            print("워치에 재생 속도 전송 완료: \(playbackRate)x")
        } catch {
            print("워치 재생 속도 전송 실패: \(error.localizedDescription)")
        }
    }
    
    /// 워치에 시스템 볼륨을 전송합니다
    func sendSystemVolumeToWatch(_ volume: Float) async {
        do {
            try await watchService.sendSystemVolume(volume)
            print("워치에 시스템 볼륨 전송 완료: \(volume)")
        } catch {
            print("워치 시스템 볼륨 전송 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Comprehensive Watch Updates
    
    /// 워치에 모든 현재 상태를 종합적으로 전송합니다 (음악 시작 시 사용)
    func sendCompleteStateToWatch() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.sendPlayingStateToWatch() }
            group.addTask { await self.sendMarkersToWatch() }
            group.addTask { await self.sendMusicTitleToWatch() }
            group.addTask { await self.sendPlaybackRateToWatch() }
        }
    }
    
    /// 워치에 실시간 업데이트 정보를 전송합니다 (타이머에서 사용)
    func sendRealTimeUpdateToWatch() async {
        // 5초마다 전체 상태 전송 (성능 최적화)
        if Int(currentTime) % 5 == 0 {
            await sendPlayingStateToWatch()
        }
    }
}

// MARK: - Watch Notification Handlers

extension PlayerViewModel {
    
    /// 워치 알림 시스템을 설정합니다
    internal func setupWatchNotifications() {
        print("🔍 setupWatchNotifications 시작")
        
        // 기존 PlayerModel의 notification 로직을 async/await 방식으로 변경
        // Notification.Name들은 Manager/WCManager.swift에서 이미 정의됨
        
        // 기본 재생 제어
        NotificationCenter.default.addObserver(
            forName: .plusCount,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handlePlayToggle()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .forward,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleForward5Seconds()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .backward,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleBackward5Seconds()
            }
        }
        
        // 속도 제어
        NotificationCenter.default.addObserver(
            forName: .increaseSpeed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleIncreaseSpeed()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .decreaseSpeed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleDecreaseSpeed()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .originalSpeed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleOriginalSpeed()
            }
        }
        
        // 마커 제어 (PlayerViewModel+Marker.swift에서 처리되지만 여기서 등록)
        NotificationCenter.default.addObserver(
            forName: .markerPlay,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int {
                Task { @MainActor in
                    await self?.handleMarkerPlay(at: index)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int {
                Task { @MainActor in
                    await self?.handleMarkerSave(at: index)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerDelete,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int {
                Task { @MainActor in
                    await self?.handleMarkerDelete(at: index)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerEdit,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let forEdit = notification.object as? [Int] {
                Task { @MainActor in
                    await self?.handleMarkerEdit(at: forEdit[0], adjustment: Double(forEdit[1]))
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .markerEditSuccess,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let forEdit = notification.object as? [Int] {
                Task { @MainActor in
                    await self?.handleMarkerEditSuccess(at: forEdit[0], newTime: Double(forEdit[1]))
                }
            }
        }
        
        // 음악 선택
        NotificationCenter.default.addObserver(
            forName: .UUIDPlay,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let uuidString = notification.object as? String,
               let musicID = UUID(uuidString: uuidString) {
                Task { @MainActor in
                    await self?.handleMusicSelection(musicID: musicID)
                }
            }
        }
        
        // 볼륨 변경
        NotificationCenter.default.addObserver(
            forName: .changeVolume,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let volume = notification.object as? Float {
                Task { @MainActor in
                    await self?.handleVolumeChange(volume: volume)
                }
            }
        }
        
        // 음악 목록 요청
        NotificationCenter.default.addObserver(
            forName: .requireMusicList,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleMusicListRequest()
            }
        }
        
        // ✅ 자동 동기화 트리거 추가
        NotificationCenter.default.addObserver(
            forName: .triggerAutoSync,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🎯 자동 동기화 트리거 수신")
            Task { @MainActor in
                await self?.handleAutoSync()
            }
        }
        
        // ✅ 즉시 상태 요청 처리 추가
        NotificationCenter.default.addObserver(
            forName: .requireCurrentState,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 iOS: 워치에서 즉시 상태 요청 수신")
            Task { @MainActor in
                await self?.handleCurrentStateRequest()
            }
        }
        
        print("✅ 워치 알림 시스템 설정 완료")
    }
    
    // MARK: - Watch Command Handlers
    
    /// 속도 증가 처리 (워치에서 호출)
    internal func handleIncreaseSpeed() async {
        let newRate = min(1.5, playbackRate + 0.1)
        do {
            try await setPlaybackRate(newRate)
            await sendPlaybackRateToWatch()
            print("워치에서 속도 증가 명령 수신: \(newRate)x")
        } catch {
            print("워치 속도 증가 처리 중 오류: \(error)")
        }
    }
    
    /// 속도 감소 처리 (워치에서 호출)
    internal func handleDecreaseSpeed() async {
        let newRate = max(0.5, playbackRate - 0.1)
        do {
            try await setPlaybackRate(newRate)
            await sendPlaybackRateToWatch()
            print("워치에서 속도 감소 명령 수신: \(newRate)x")
        } catch {
            print("워치 속도 감소 처리 중 오류: \(error)")
        }
    }
    
    /// 원래 속도로 복원 처리 (워치에서 호출)
    internal func handleOriginalSpeed() async {
        do {
            try await setPlaybackRate(1.0)
            await sendPlaybackRateToWatch()
            print("워치에서 원래 속도 복원 명령 수신")
        } catch {
            print("워치 원래 속도 복원 처리 중 오류: \(error)")
        }
    }
    
    /// 마커 편집 성공 처리 (워치에서 호출) - 수정된 버전
    internal func handleMarkerEditSuccess(at index: Int, newTime: Double) async {
        guard index >= 0 && index < 3 else { return }
        guard markers[index] != -1 else { return }
        
        // ✅ 절대값으로 마커 시간 설정
        await editMarker(at: index, to: max(0, newTime))
        
        print("워치에서 마커 편집 성공 명령 수신: 마커 \(index + 1), 새로운 시간: \(formattedTime(newTime))")
    }
    
    /// 음악 선택 처리 (워치에서 호출) - 개선된 버전
    internal func handleMusicSelection(musicID: UUID) async {
        print("🎯 워치에서 음악 선택 명령 수신: \(musicID)")
        
        // SwiftData에서 최신 음악 목록 먼저 로드
        await loadMusicListFromSwiftData()
        
        // 현재 음악 목록에서 해당 ID의 음악 찾기
        guard let musicData = musicList.first(where: { $0.id == musicID }) else {
            print("❌ 워치에서 요청한 음악을 찾을 수 없음: \(musicID)")
            print("   - 현재 음악 목록: \(musicList.map { "\($0.title)(\($0.id))" })")
            
            // 음악을 찾을 수 없으면 최신 음악 목록을 다시 전송
            await sendMusicListToWatch()
            return
        }
        
        // ✅ 이미 같은 음악이 재생 중이면 아무것도 하지 않음 (토글하지 않음)
        if currentMusic?.id == musicID {
            print("🎯 이미 선택된 음악입니다. 상태 유지: \(musicData.title)")
            
            // 워치에 현재 상태만 다시 전송 (재생 상태 동기화)
            await sendCompleteStateToWatch()
            return
        }
        
        // 새로운 음악 재생
        await playMusic(musicData)
        print("✅ 워치에서 음악 선택 완료: \(musicData.title)")
        
        // 워치에 전체 상태 업데이트 전송
        await sendCompleteStateToWatch()
    }
    
    /// 볼륨 변경 처리 (워치에서 호출)
    internal func handleVolumeChange(volume: Float) async {
        await sendSystemVolumeToWatch(volume)
        print("워치에서 볼륨 변경 명령 수신: \(volume)")
    }
    
    /// 음악 목록 요청 처리 (워치에서 호출) - 개선된 버전
    internal func handleMusicListRequest() async {
        print("🎯 워치에서 음악 목록 요청 수신!")
        print("   - 현재 음악 개수: \(musicList.count)")
        print("   - 워치 연결 상태: connected=\(watchService.isConnected), reachable=\(watchService.isReachable)")
        
        // 연결 상태 확인
        guard watchService.isConnected && watchService.isReachable else {
            print("⚠️ 워치가 연결되지 않아 음악 목록 전송을 건너뜁니다")
            return
        }
        
        // 음악 목록 전송
        print("   - 음악 목록 전송 시작")
        await sendMusicListToWatch()
        
        // 현재 재생 중인 음악이 있다면 전체 상태도 함께 전송
        if let currentMusic = currentMusic {
            print("🎯 현재 재생 중인 음악이 있어 전체 상태도 전송합니다: \(currentMusic.title)")
            await sendCompleteStateToWatch()
        }
        
        print("✅ 워치 음악 목록 요청 처리 완료")
    }
    
    /// 자동 동기화 처리
    internal func handleAutoSync() async {
        print("🔄 handleAutoSync 시작")
        
        // 연결 상태 확인
        print("   - watchService.isConnected: \(watchService.isConnected)")
        print("   - watchService.isReachable: \(watchService.isReachable)")
        
        guard watchService.isConnected && watchService.isReachable else {
            print("⚠️ 워치 연결 안됨 - 자동 동기화 건너뜀")
            return
        }
        
        // 음악 목록 전송
        print("   - 음악 목록 전송 시작")
        await sendMusicListToWatch()
        
        // 현재 재생 중인 음악이 있다면 전체 상태도 함께 전송
        if let currentMusic = currentMusic {
            print("   - 현재 재생 중인 음악이 있어 전체 상태도 전송합니다: \(currentMusic.title)")
            await sendCompleteStateToWatch()
        }
        
        print("✅ handleAutoSync 완료")
    }

    // MARK: - Immediate State Request Handler
    
    /// 워치에서 즉시 상태 요청을 받았을 때 처리
    @MainActor
    private func handleCurrentStateRequest() async {
        print("🚀 iOS: 워치에 즉시 상태 전송 시작")
        await sendPlayingStateToWatch()
        
        // 추가로 다른 중요한 상태들도 전송
        await sendPlaybackRateToWatch()
        await sendMarkersToWatch()
        print("✅ iOS: 워치에 즉시 상태 전송 완료")
    }
}

// MARK: - Watch Integration Support

extension PlayerViewModel {
    
    /// 새 음악 재생 시 워치 상태 전체 업데이트
    func notifyWatchOfNewMusic(_ musicData: MusicData) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.sendMusicTitleToWatch() }
            group.addTask { await self.sendMarkersToWatch() }
            group.addTask { await self.sendPlayingStateToWatch() }
            group.addTask { await self.sendPlaybackRateToWatch() }
        }
        
        print("워치에 새 음악 정보 전송 완료: \(musicData.title)")
    }
    
    /// 음악 중지 시 워치에 알림
    func notifyWatchOfMusicStop() async {
        do {
            try await watchService.sendPlayingState(
                isPlaying: false,
                currentTime: 0,
                duration: 0
            )
            print("워치에 음악 중지 상태 전송 완료")
        } catch {
            print("워치 음악 중지 알림 실패: \(error)")
        }
    }
    
    /// 워치 연결 상태 확인
    var isWatchConnected: Bool {
        return watchService.isConnected && watchService.isReachable
    }
    
    /// 워치 연결 상태 디버깅 정보
    var watchConnectionDebugInfo: String {
        return """
        Watch Connection Info:
        - Connected: \(watchService.isConnected)
        - Reachable: \(watchService.isReachable)
        - Current Music: \(currentMusic?.title ?? "None")
        - Markers: \(markers)
        """
    }
}

// MARK: - Watch Message Delegate Support

extension PlayerViewModel {
    
    /// WatchMessageDelegate를 설정합니다
    func setupWatchMessageDelegate() {
        // 현재 PlayerViewModel이 직접 delegate 역할을 할 수도 있음
        // 또는 별도의 delegate 객체를 만들어서 사용할 수도 있음
        // watchService.setMessageDelegate(self)
        
        // TODO: WatchMessageDelegate 구현이 필요하면 추가
    }
}
