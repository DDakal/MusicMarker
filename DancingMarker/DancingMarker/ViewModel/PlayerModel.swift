//
//  ViewModel.swift
//  DancingMarker
//
//  Created by 변준섭 on 7/16/24.
//

import SwiftUI
import NotificationCenter
import AVFoundation
import MediaPlayer
import SwiftData

class PlayerModel: ObservableObject {
    
    @Published var music: Music?
    
    @Environment(\.modelContext) private var modelContext
    var connectivityManager: WatchConnectivityManager
    
    @Environment(NavigationManager.self) var navigationManager
    
    @Published var musicList: [Music] = []
    
    @Published var progress: Double = 0.0 // 예시로 초기값 설정
    @Published var formattedProgress = "0:00"
    @Published var formattedDuration = "0:00"
    @Published var duration: TimeInterval = 0.0 // 예시로 재생 시간 설정
    @Published var currentTime: TimeInterval = 0.0 // 예시로 현재 시간 설정
    
    @Published var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    @Published var playbackRate: Float = 1.0
    @Published var isPlaying = false
    @Published var isDragging = false
    
    @Published var countNum: Int = 0
    
    @Published var isEditing: Bool = false
    @Published var editingIndex: Int? = nil
    @Published var editingMarker: TimeInterval = 0.0
    
    init(connectivityManager: WatchConnectivityManager) {
        self.connectivityManager = connectivityManager
        setupAudioSession()
        setupControlCenterControls()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationPlaytoggleAction),
            name: .plusCount,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationForwardAction),
            name: .forward,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationBackwardAction),
            name: .backward,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationMarkerPlayAction),
            name: .markerPlay,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationMarkerSaveAction),
            name: .markerSave,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationDecreaseSpeedAction),
            name: .decreaseSpeed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationIncreaseSpeedAction),
            name: .increaseSpeed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationOriginalSpeedAction),
            name: .originalSpeed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationRequireMusicListAction),
            name: .requireMusicList,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationUUIDPlayAction),
            name: .UUIDPlay,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationMarkerDeleteAction),
            name: .markerDelete,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationMarkerEditAction),
            name: .markerEdit,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationMarkerEditSuccessAction),
            name: .markerEditSuccess,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(notificationChangeVolumeAction),
            name: .changeVolume,
            object: nil
        )
    }
    
    @objc func notificationPlaytoggleAction(_ notification: Notification) {
        self.countNum = countNum + 1
        togglePlayback()
    }
    
    @objc func notificationForwardAction(_ notification: Notification) {
        self.countNum = countNum + 1
        DispatchQueue.main.async{
            self.forward5Sec()
            //            self.connectivityManager.sendPlayingTimesToWatch([self.currentTime, self.duration])
        }
    }
    
    @objc func notificationBackwardAction(_ notification: Notification) {
        self.countNum = countNum + 1
        DispatchQueue.main.async{
            self.backward5Sec()
            //            self.connectivityManager.sendPlayingTimesToWatch([self.currentTime, self.duration])
        }
    }
    
    @objc func notificationIncreaseSpeedAction(_ notification: Notification) {
        self.countNum = countNum + 1
        increasePlaybackRate()
    }
    
    @objc func notificationDecreaseSpeedAction(_ notification: Notification) {
        self.countNum = countNum + 1
        decreasePlaybackRate()
    }
    
    @objc func notificationOriginalSpeedAction(_ notification: Notification) {
        self.countNum = countNum + 1
        self.playbackRate = 1.0
        self.updateAudioPlayer()
    }
    
    @objc func notificationMarkerPlayAction(_ notification: Notification) {
        self.countNum += 1
        guard let music = music else { return }
        
        if let index = notification.object as? Int, index >= 0, index < music.markers.count {
            DispatchQueue.main.async{
                let marker = music.markers[index]
                guard let audioPlayer = self.audioPlayer else { return }
                audioPlayer.currentTime = marker
                self.progress = CGFloat(marker / self.duration)
                self.formattedProgress = self.formattedTime(marker)
                audioPlayer.play()
                self.isPlaying = true
                self.sendPlayingInformation()
            }
        } else {
            print("Invalid marker index or index out of bounds")
        }
    }
    
    @objc func notificationMarkerSaveAction(_ notification: Notification) {
        self.countNum = countNum + 1
        guard let music = music else { return }
        if let index = notification.object as? Int, index >= 0, index < music.markers.count {
            guard let audioPlayer = audioPlayer else { return }
            music.markers[index] = audioPlayer.currentTime
            self.connectivityManager.sendMarkersToWatch(music.markers)
        } else {
            print("Invalid marker index or index out of bounds")
        }
    }
    
    @objc func notificationRequireMusicListAction(_ notification: Notification) {
        self.countNum = countNum + 1
        self.sendMusicListToWatch(with: musicList)
    }
    
    @objc func notificationUUIDPlayAction(_ notification: Notification) {
        self.countNum += 1
        if let uuid = notification.object as? String, let idToPlay = UUID(uuidString: uuid) {
            if let selectedMusic = musicList.first(where: { $0.id == idToPlay }) {
                DispatchQueue.main.async{
                    if self.music == nil {
                        // 음원이 nil 일 때 (처음 노래를 켤 때)
                        self.music = selectedMusic
                        self.isPlaying = true
                        self.initAudioPlayer(for: selectedMusic)
                        self.playAudio()
                        print("음원 \(self.music?.title)으로 처음 재생됨")
                    } else if self.music?.id == selectedMusic.id {
                        // 현재 재생 중인 음원과 동일할 때
                        print("음원 그대로임 \(self.music?.title)")
                        if !self.isPlaying {
                            // 음원이 정지된 상태라면 재생 시작
                            print("정지였었삼: \(self.music?.title)")
                            self.isPlaying = true
                            self.playAudio()
                        }
                    } else {
                        // 새로운 음원으로 변경되었을 경우
                        self.stopAudio()
                        self.stopTimer() // 기존 타이머 중지
                        
                        self.music = selectedMusic
                        self.isPlaying = true
                        self.initAudioPlayer(for: selectedMusic)
                        print("음원 \(self.music?.title)으로 바뀜")
                        
                        self.playAudio()
                    }
                    if let audioPlayer = self.audioPlayer {
                        self.currentTime = audioPlayer.currentTime
                        self.duration = audioPlayer.duration
                    }
                    self.sendPlayingInformation()
                }
                
            }
        } else {
            print("Invalid UUID string or object is not a string.")
        }
    }
    
    @objc func notificationMarkerDeleteAction(_ notification: Notification) {
        self.countNum = countNum + 1
        if let index = notification.object as? Int {
            guard let music = self.music else { return }
            
            do {
                self.deleteMarker(at: index)
                try modelContext.save()
                self.connectivityManager.sendMarkersToWatch(music.markers)
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        } else {
            print("Invalid marker index or index out of bounds")
        }
    }
    
    @objc func notificationMarkerEditAction(_ notification: Notification) {
        self.countNum += 1
        guard let music = music else { return }
        
        if let forEdit = notification.object as? [Int]{
            DispatchQueue.main.async{
                let marker = music.markers[forEdit[0]]+Double(forEdit[1])
                guard let audioPlayer = self.audioPlayer else { return }
                audioPlayer.currentTime = marker
                self.progress = CGFloat(marker / self.duration)
                self.formattedProgress = self.formattedTime(marker)
                audioPlayer.play()
                self.isPlaying = true
                self.sendPlayingInformation()
            }
        } else {
            print("Invalid marker index or index out of bounds")
        }
    }
    
    @objc func notificationMarkerEditSuccessAction(_ notification: Notification) {
        self.countNum += 1
        guard let music = music else { return }
        
        if let forEdit = notification.object as? [Int]{
            let marker = music.markers[forEdit[0]]+Double(forEdit[1])
            guard let audioPlayer = audioPlayer else { return }
            music.markers[forEdit[0]] = marker
            self.connectivityManager.sendMarkersToWatch(music.markers)
        } else { }
    }
    
    @objc func notificationChangeVolumeAction(_ notification: Notification) {
        self.countNum += 1
        guard let music = music else { return }
        
        if let volume = notification.object as? Float{
            self.setPlayerVolume(volume)
        } else { }
    }
    
    func addMarkerButton(index: Int) -> some View {
        Button(action: {
            DispatchQueue.main.async{
                guard let music = self.music else { return }
                self.addMarker(at: index)
                self.connectivityManager.sendMarkersToWatch(music.markers)
            }
            
        }) {
            HStack(spacing: 8) {
                Image("emptyMarker")
                Text("Local_MarkerAdd")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(width: 360, height: 60)
            .background(Color.buttonDarkGray)
            .cornerRadius(12)
            
        }
    }
    
    func addMarker(at index: Int) {
        guard let audioPlayer = audioPlayer else { return }
        guard let music = music else { return }
        let newMarker = audioPlayer.currentTime
        
        music.markers[index] = newMarker
        //TODO: modelContext에 마커 넣기
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    @ViewBuilder
    func markerButton(for marker: TimeInterval, index: Int) -> some View {
        if isEditing && editingIndex == index {
            editMarkerButton(for: marker, index: index)
        } else {
            Button(action: {
                self.moveToMarker(marker)
            }) {
                HStack(spacing: 8) {
                    Image("addedMarker")
                    Text(formattedTime(marker))
                        .font(.title3)
                        .italic()
                        .foregroundColor(.black)
                }
                .frame(width: 360, height: 60)
                .background(.accent)
                .cornerRadius(12)
            }
            .contextMenu {
                Button(action: {
                    self.isEditing = true
                    self.editingIndex = index
                    self.editingMarker = marker
                }) {
                    Text("Local_MarkerEdit")
                    Image(systemName: "pencil")
                }
                Button(role: .destructive, action: {
                    self.deleteMarker(at: index)
                }) {
                    Text("Local_MarkerReset")
                    Image(systemName: "eraser")
                }
            }
        }
    }
    
    @ViewBuilder
    func editMarkerButton(for marker: TimeInterval, index: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.inactiveGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image("backward1SecIcon")
                    
                }
                .onTapGesture {
                    if self.editingMarker > 1 {
                        self.editingMarker -= 1
                    }
                }
            
            HStack(spacing: 8) {
                Text(formattedTime(editingMarker)) // editingMarker 사용
                    .font(.title3)
                    .italic()
                    .foregroundColor(.black)
            }
            .frame(width: 200, height: 60)
            .background(.accent)
            .cornerRadius(12)
            .padding(.horizontal, 6)
            
            Circle()
                .fill(.inactiveGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image("forward1SecIcon")
                    
                }
                .onTapGesture {
                    if self.editingMarker < self.duration - 1 {
                        self.editingMarker += 1
                    }
                }
            
            Circle()
                .fill(.buttonDarkGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.green)
                    
                }
                .padding(.leading, 10)
                .onTapGesture {
                    self.saveMarker(at: index, with: self.editingMarker)
                    self.isEditing = false
                    self.editingIndex = nil
                }
        }
    }
    
    /// 마커 수정에 필요한 기능
    func saveMarker(at index: Int, with time: TimeInterval) {
        guard let music = music else { return }
        music.markers[index] = time
        do {
            try modelContext.save()
            self.connectivityManager.sendMarkersToWatch(music.markers)
        } catch {
            print("Failed to save context after saving marker: \(error.localizedDescription)")
        }
    }
    
    private func deleteMarker(at index: Int) {
        guard let music = self.music else { return }
        
        music.markers[index] = -1
        //self.connectivityManager.sendMarkersToWatch(music.markers)
        
        do {
            try modelContext.save()
            self.connectivityManager.sendMarkersToWatch(music.markers)
        } catch {
            print("Failed to save context after deleting marker: \(error.localizedDescription)")
        }
    }
    
    private func moveToMarker(_ marker: TimeInterval) {
        self.audioPlayer?.currentTime = marker
        self.progress = CGFloat(marker / self.duration)
        self.formattedProgress = self.formattedTime(marker)
        audioPlayer?.play()
        isPlaying = true
        
        connectivityManager.sendPlayingTimesToWatch([currentTime, duration])
        connectivityManager.sendIsPlayingToWatch(isPlaying)
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: time)!
    }
    
    /// 배속 조절 기능
    func decreasePlaybackRate() {
        if self.playbackRate > 0.5 {
            self.playbackRate -= 0.1
            self.updateAudioPlayer()
        }
    }
    
    func increasePlaybackRate() {
        if self.playbackRate < 1.5 {
            self.playbackRate += 0.1
            self.updateAudioPlayer()
        }
    }
    
    func updateAudioPlayer() {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.rate = playbackRate
        connectivityManager.sendSpeedToWatch(playbackRate)
    }
    
    func updateAudioPlayer(with time: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        audioPlayer.currentTime = time
        connectivityManager.sendPlayingTimesToWatch([currentTime, duration])
    }
    
    /// 음원 재생, 조작, 초기화
    func play(music: Music) {
        // 1. 재생하려는 음악이 현재 음악과 같은지 확인
        if self.music?.id == music.id {
            // 이미 재생 중이면 아무것도 안 함
            if self.isPlaying {
                print("이미 같은 곡이 재생 중입니다.")
                return
            }
            // 정지 상태면 재생만 함
            else {
                self.playAudio()
            }
        }
        // 2. 다른 음악일 경우, 새로 초기화하고 재생
        else {
            self.stopAudio() // 현재 플레이어 완전 정지
            self.stopTimer() // 타이머 정지
            
            self.music = music // 모델의 현재 음악을 새 음악으로 교체
            self.initAudioPlayer(for: music) // 새 음악으로 플레이어 초기화
            self.playAudio() // 재생 시작
            
            print("🎶 \(music.title) 으로 음원을 변경하고 재생합니다.")
        }
        
        // 워치와 컨트롤센터에 정보 전송
        self.sendPlayingInformation()
        self.updateNowPlayingControlCenter()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("🚨 Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func playAudio() {
        audioPlayer?.play()
        isPlaying = true
        updateNowPlayingControlCenter() // 상태 변경 후 컨트롤 센터 업데이트
        print("▶️ Playing audio. isPlaying = \(isPlaying)")
    }

    // 일시정지
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        updateNowPlayingControlCenter()
        print("⏸️ Pausing audio. isPlaying = \(isPlaying)")
    }
    
    // 다른 곡으로 넘어갈 때 초기화
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        // stop은 재생 위치를 0으로 되돌리므로, currentTime도 0으로 맞춰주는 것이 좋음
        currentTime = 0
        progress = 0
        formattedProgress = formattedTime(0)
        updateNowPlayingControlCenter()
        print("⏹️ Stopping audio. isPlaying = \(isPlaying)")
    }
    
    /// iOS 제어 센터와 잠금 화면에서의 음악 재생 제어를 설정합니다.
    /// 재생/일시정지, 5초 앞/뒤로 이동, 재생 위치 변경 등의 기능을 제공합니다.
    private func setupControlCenterControls() {
            let commandCenter = MPRemoteCommandCenter.shared()
            
            commandCenter.playCommand.removeTarget(nil)
            commandCenter.pauseCommand.removeTarget(nil)
            commandCenter.togglePlayPauseCommand.removeTarget(nil)
            commandCenter.skipBackwardCommand.removeTarget(nil)
            commandCenter.skipForwardCommand.removeTarget(nil)
            commandCenter.changePlaybackPositionCommand.removeTarget(nil)
            
            commandCenter.playCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                if !self.isPlaying {
                    self.playAudio() // playAudio() 호출
                }
                return .success
            }
            
            commandCenter.pauseCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                if self.isPlaying {
                    self.pauseAudio()
                }
                return .success
            }
            
            commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                self.togglePlayback()
                return .success
            }
            
            commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                self.backward5Sec()
                return .success
            }
            
            commandCenter.skipForwardCommand.addTarget { [weak self] _ in
                guard let self = self else { return .commandFailed }
                self.forward5Sec()
                return .success
            }
            
            commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                guard let self = self else { return .commandFailed }
                if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                    self.seekToTime(to: positionEvent.positionTime) // seekToTime으로 변경
                    return .success
                }
                return .commandFailed
            }
            
            commandCenter.skipBackwardCommand.preferredIntervals = [5]
            commandCenter.skipForwardCommand.preferredIntervals = [5]
            
            commandCenter.playCommand.isEnabled = true
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.togglePlayPauseCommand.isEnabled = true
            commandCenter.skipBackwardCommand.isEnabled = true
            commandCenter.skipForwardCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.isEnabled = true
        }
    
    func initAudioPlayer(for music: Music) {
            audioPlayer?.stop()
            audioPlayer = nil
            
            let musicFileURL = music.fileURL
            guard FileManager.default.fileExists(atPath: musicFileURL.path) else {
                print("🚨 File not found at path: \(musicFileURL.path)")
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: musicFileURL)
                guard let audioPlayer = self.audioPlayer else { return }
                
                audioPlayer.prepareToPlay()
                audioPlayer.enableRate = true
                audioPlayer.numberOfLoops = -1
                
                duration = audioPlayer.duration
                formattedDuration = formattedTime(audioPlayer.duration)
                
                remoteControlCenterInfo() // Now Playing 정보 설정
                startTimer()
                
            } catch {
                print("🚨 Error initializing audio player: \(error.localizedDescription)")
            }
        }
    
    func togglePlayback() {
        guard let audioPlayer = self.audioPlayer else {
            print("Audio player is not available.")
            return
        }
        
        if self.isPlaying {
            print("멈춤 audio.")
            self.stopAudio()
        } else {
            print("플레잉 audio.")
            self.playAudio()
        }
        
        // 백그라운드, 워치에 반영하기
        self.updateNowPlayingControlCenter()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateNowPlayingControlCenter()
        }
    }
    
    func startTimer() {
        // 기존 타이머가 있으면 무효화
        timer?.invalidate()
        
        // 새로운 타이머 설정
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let audioPlayer = self.audioPlayer else { return }
            
            if !audioPlayer.isPlaying {
                self.isPlaying = false
            }
            
            if !self.isDragging {
                self.currentTime = audioPlayer.currentTime
                self.progress = audioPlayer.duration > 0 ? Double(audioPlayer.currentTime / audioPlayer.duration) : 0
                self.formattedProgress = self.formattedTime(audioPlayer.currentTime)
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 음원 5초 앞으로 뒤로 가기 기능
    func seekToTime(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        DispatchQueue.main.async{
            player.currentTime = time
            self.currentTime = time
            self.progress = CGFloat(time / player.duration)
            self.formattedProgress = self.formattedTime(time)
            self.updateNowPlayingControlCenter()
            self.connectivityManager.sendPlayingTimesToWatch([player.currentTime, self.duration])
        }
    }
    
    func backward5Sec() {
        guard let player = audioPlayer else { return }
        DispatchQueue.main.async {
            let newTime = max(player.currentTime - 5, 0)
            self.seekToTime(to: newTime)
        }
    }
    
    func forward5Sec() {
        guard let player = audioPlayer else { return }
        DispatchQueue.main.async {
            let newTime = min(player.currentTime + 5, player.duration)
            self.seekToTime(to: newTime)
        }
    }
    
    func sendMusicListToWatch(with musicList: [Music]) {
        print(musicList.count)
        self.musicList = musicList
        if musicList.count != 0{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                let musicTitles = musicList.map { [$0.title, $0.id.uuidString] }
                self.connectivityManager.sendMusicListToWatch(musicTitles)
                print(musicTitles)
            }
        } else {
            self.connectivityManager.sendMusicListToWatch([["", ""]])
            print("no swiftdata musicList")
        }
    }
    
    func sendPlayingInformation() {
        DispatchQueue.main.async{
            if let audioPlayer = self.audioPlayer{
                self.currentTime = audioPlayer.currentTime
            }
            self.connectivityManager.sendIsPlayingToWatch(self.isPlaying)
            self.connectivityManager.sendPlayingTimesToWatch([self.currentTime, self.duration])
            if let music = self.music{
                self.connectivityManager.sendMarkersToWatch(music.markers)
                self.connectivityManager.sendTitleToWatch(music.title)
            }
        }
    }
    
    func setPlayerVolume(_ volume: Float) {
        MPVolumeView.setVolume(volume)
    }

    /// LiveActivity 함수 (백그라운드 재생, 정지, 5초 앞뒤로)
    private func remoteControlCenterInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        if let music = self.music {
            // 앨범 아트가 있는 경우
            if let albumArtData = music.albumArt, let albumArt = UIImage(data: albumArtData) {
                let artwork = MPMediaItemArtwork(boundsSize: albumArt.size, requestHandler: { size in
                    return albumArt
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            } else {
                // 앨범 아트가 없을 경우 기본 이미지 사용
                let liveActivityArtwork = liveActivityPlaceholderArtwork()
                let artwork = MPMediaItemArtwork(boundsSize: liveActivityArtwork.size, requestHandler: { size in
                    return liveActivityArtwork
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
            
            nowPlayingInfo[MPMediaItemPropertyTitle] = music.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = music.artist
        } else {
            // 음악이 없을 경우 모든 정보 초기화
            nowPlayingInfo.removeAll()
        }

        nowPlayingInfo[MPMediaItemPropertyTitle] = self.music?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.music?.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentTime

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlayingControlCenter() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        guard let music = self.music, let audioPlayer = self.audioPlayer else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        // 현재 재생 시간과 재생 속도 업데이트
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer.currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? NSNumber(value: self.playbackRate) : NSNumber(value: 0)
            
            // 재생 상태를 명시적으로 설정
            if self.isPlaying {
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: self.playbackRate)
            } else {
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 0)
            }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        // 워치에 재생 정보 반영
        self.connectivityManager.sendIsPlayingToWatch(self.isPlaying)
        self.connectivityManager.sendPlayingTimesToWatch([self.currentTime, self.duration])
    }
    
    // LiveActivity 재생 위치 변경 함수
    func changePlaybackPosition(to position: TimeInterval) {
        guard let audioPlayer = self.audioPlayer else { return }
        
        // 오디오 플레이어의 재생 위치를 업데이트
        audioPlayer.currentTime = position
        self.currentTime = position
        
        // 백그라운드 재생 정보 업데이트
        updateNowPlayingControlCenter()

        print("Playback position changed to \(position)")
    }
}

func liveActivityPlaceholderArtwork() -> UIImage {
    // Placeholder 뷰 생성
    let rect = CGRect(x: 0, y: 0, width: 66, height: 66)
    let view = UIView(frame: rect)
    
    // RoundedRectangle 설정
    let roundedRect = UIView(frame: rect)
    roundedRect.clipsToBounds = true
    view.addSubview(roundedRect)
    
    // 음악 아이콘 추가
    let imageView = UIImageView(image: UIImage(systemName: "music.note"))
    imageView.tintColor = .gray
    imageView.contentMode = .scaleAspectFit
    imageView.frame = roundedRect.bounds.insetBy(dx: 10, dy: 10)
    roundedRect.addSubview(imageView)
    
    // `UIView`를 `UIImage`로 변환
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image ?? UIImage()
}


extension MPVolumeView {
    static func setVolume(_ volume: Float) -> Void {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: {$0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
