//
//  ViewModel.swift
//  WatchDancingMarker Watch App
//
//  Created by 변준섭 on 7/16/24.
//
import SwiftUI
import SwiftData

class WatchViewModel: ObservableObject {
    
    var connectivityManager: WatchConnectivityManager
    @Published var musicTitle: String  = ""
    @Published var markers: [String] = ["99:59", "99:59", "99:59"]
    @Published var timeintervalMarkers: [TimeInterval] = [0.0, 0.0, 0.0]
    @Published var speed: Float = 1.0
    @Published var isPlaying = false
    
    @Published var progress: Double = 0.0 // 예시로 초기값 설정
    @Published var formattedProgress = "0:00"
    @Published var formattedDuration = "0:00"
    @Published var duration: TimeInterval = 0.0 // 예시로 재생 시간 설정
    @Published var currentTime: TimeInterval = 0.0 // 예시로 현재 시간 설정
    @Published var musicList: [[String]] = []
    
    @Published var crownVolume: Float = 0.5  // 초기 볼륨 값 (0.0 ~ 1.0)
    @Published var lastSentCrownValue: Float = 0.5  // 마지막으로 전송된 Crown 값

    @Published private var isMarkerSeeking: Bool = false
    
    private var timer: Timer?
    
    init(connectivityManager: WatchConnectivityManager) {
        self.connectivityManager = connectivityManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMarkers(_:)),
            name: .sendMarkers,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateSpeed(_:)),
            name: .sendSpeed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateIsPlaying(_:)),
            name: .sendIsPlaying,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updatePlayingTimes(_:)),
            name: .sendPlayingTimes,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMusicList(_:)),
            name: .sendMusicList,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMusicTitle(_:)),
            name: .sendMusicTitle,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setVolumeBySystem(_:)),
            name: .sendSystemVolume,
            object: nil
        )
        self.musicList = UserDefaults.standard.getMusicList()
    }
    convenience init() {
        self.init(connectivityManager: WatchConnectivityManager())
    }
    
    @objc func updateMarkers(_ notification: Notification) {
        if let markers = notification.object as? [TimeInterval] {
            self.timeintervalMarkers = markers
            for index in markers.indices{
                if markers[index] != -1{
                    self.markers[index] = formattedTime(markers[index])
                } else{
                    self.markers[index] = "99:59"
                }
            }
        }
    }
    
    @objc func updateSpeed(_ notification: Notification) {
        if let speed = notification.object as? Float {
            self.speed = speed
        }
    }
    
    @objc func updateIsPlaying(_ notification: Notification) {
        if let isPlaying = notification.object as? Bool {
            self.isPlaying = isPlaying
            if isPlaying {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    
    @objc func updatePlayingTimes(_ notification: Notification) {
        if let playingTimes = notification.object as? [TimeInterval] {
            DispatchQueue.main.async{
                self.currentTime = playingTimes[0]
                self.duration = playingTimes[1]
                self.progress = self.currentTime / self.duration
                self.formattedProgress = self.formattedTime(self.currentTime)
            }
        }
    }
    
    @objc func updateMusicList(_ notification: Notification) {
        if let musics = notification.object as? [[String]] {
            // UserDefaults를 초기화하고 새로운 musicList를 저장합니다.
            UserDefaults.standard.clearMusicList()
            UserDefaults.standard.saveMusicList(musics)
            self.musicList = musics
        }
    }
    
    @objc func updateMusicTitle(_ notification: Notification) {
        if let musicTitle = notification.object as? String {
            self.musicTitle = musicTitle
        }
    }
    
    @objc func setVolumeBySystem(_ notification: Notification) {
        if let systemVolume = notification.object as? Float {
            self.crownVolume = systemVolume * 60
        }
    }
    
    func playToggle() {
        connectivityManager.sendPlayToggleToIOS()
    }
    
    func playForward() {
        connectivityManager.sendForwardToIOS()
    }
    
    func playBackward() {
        connectivityManager.sendBackwardToIOS()
    }
    
    func decreasePlaybackRate() {
        connectivityManager.sendDecreasePlaybackToIOS()
    }
    
    func increasePlaybackRate() {
        connectivityManager.sendIncreasePlaybackToIOS()
    }
    
    func originalPlaybckRate() {
        connectivityManager.sendOriginalPlaybackToIOS()
    }
    
    func requireMusicList() {
        //        connectivityManager.
    }
    
    func sendUUID(id: String) {
        connectivityManager.sendUUIDPlayToIOS(id)
    }
    
    func deletemarker(index: Int){
        connectivityManager.sendMarkerDeleteToIOS(index)
    }
    
    func changeVolume(){
        let volumeToSend = self.crownVolume / 60
        connectivityManager.sendVolumeChangeToIOS(volumeToSend)
    }
    
    func handleCrownValueChange(_ newValue: Float) {
        // 일정 수준 이상 변화했을 때만 iOS로 메시지 전송
        let threshold: Float = 0.05  // 변화 임계값
        if abs(newValue - lastSentCrownValue) >= threshold {
            let volumeToSend = self.crownVolume / 60
            connectivityManager.sendVolumeChangeToIOS(volumeToSend)
            lastSentCrownValue = newValue  // 마지막 전송 값 업데이트
        }
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: time)!
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTime() {
        guard isPlaying else { return }
        currentTime += 1
        if currentTime >= duration {
            currentTime = 0
            stopTimer()
            isPlaying = false
        }
        progress = currentTime / duration
        formattedProgress = formattedTime(currentTime)
    }
    
    func withMarkerSeekingProtection<T>(_ operation: () async throws -> T) async rethrows -> T? {
        guard !isMarkerSeeking else {
            print("⚠️ 마커 이동 중 - 추가 요청 무시")
            return nil
        }
        
        isMarkerSeeking = true
        
        // 0.8초 후 플래그 해제 (충분한 시간 확보)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            self.isMarkerSeeking = false
            print("✅ 마커 연타 방지 플래그 해제")
        }
        
        return try await operation()
    }
}

extension UserDefaults {
    private enum Keys {
        static let musicList = "musicList"
    }
    
    func saveMusicList(_ list: [[String]]) {
        set(list, forKey: Keys.musicList)
    }
    
    func getMusicList() -> [[String]] {
        return array(forKey: Keys.musicList) as? [[String]] ?? []
    }
    
    func clearMusicList() {
        removeObject(forKey: Keys.musicList)
    }
}

// MARK: - ApplicationContext 처리 메서드들

extension WatchViewModel {
    
    /// ApplicationContext에서 음악 목록을 로드합니다
    func loadMusicListFromApplicationContext() {
        if let musicList = connectivityManager.getMusicListFromApplicationContext() {
            print("✅ WatchViewModel: ApplicationContext에서 음악 목록 로드: \(musicList.count)개")
            
            // UserDefaults에 저장
            UserDefaults.standard.clearMusicList()
            UserDefaults.standard.saveMusicList(musicList)
            
            // ViewModel 업데이트
            DispatchQueue.main.async {
                self.musicList = musicList
            }
            
            return
        }
        
        print("ℹ️ WatchViewModel: ApplicationContext에 음악 목록 없음")
    }
    
    /// ApplicationContext가 유효한지 확인합니다
    func isApplicationContextValid() -> Bool {
        return connectivityManager.isApplicationContextValid()
    }
    
    /// ApplicationContext에서 마지막 업데이트 시간을 가져옵니다
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval? {
        return connectivityManager.getLastUpdateTimeFromApplicationContext()
    }
    
    /// 통합 동기화 메서드 (ApplicationContext + 실시간 요청)
    func syncMusicListOnAppear() async {
        print(" WatchViewModel: 통합 동기화 시작")
        
        // 1단계: ApplicationContext 먼저 확인
        loadMusicListFromApplicationContext()
        
        // 2단계: 연결 대기 후 실시간 요청
        await waitForConnectionAndRequestSync()
    }
    
    /// 연결 대기 후 실시간 동기화 요청
    private func waitForConnectionAndRequestSync() async {
        print("   - 연결 대기 시작...")
        
        // 연결 대기 (최대 3초)
        for attempt in 1...30 {
            if connectivityManager.isReachable {
                print("✅ 워치 연결됨! (시도 \(attempt)번째)")
                break
            }
            
            if attempt == 30 {
                print("⚠️ 워치 연결 시간 초과 - ApplicationContext 데이터 사용")
                return
            }
            
            // ✅ 0.1초 대기 (100ms)
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        // 실시간 동기화 요청
        print("   - iOS 앱에 실시간 동기화 요청")
        connectivityManager.sendRequireMusicListToIOS()
    }
}
