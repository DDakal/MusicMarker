//
//  WCManager.swift
//  DancingMarker
//
//  Created by 변준섭 on 7/15/24.
//

import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    
    private let session: WCSession = WCSession.default
    @Published var isReachable = false
    
    static let shared = WatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate (필수 메서드들)
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        print("🔍 WCManager: 세션 활성화 완료")
        print("   - activationState: \(activationState.rawValue)")
        print("   - isReachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("   - isReachable 업데이트: \(self.isReachable)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("🔍 WCManager: Reachability 변경")
        print("   - isReachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("   - isReachable 업데이트: \(self.isReachable)")
        }
    }
    
    // MARK: - iOS 전용 WCSessionDelegate 메서드들
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // iOS에서만 필요한 메서드
        print("Session did become inactive: \(session.activationState.rawValue)")
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        // iOS에서만 필요한 메서드
        print("🔍 Session watch state did change")
        print("   - activationState: \(session.activationState.rawValue)")
        print("   - isPaired: \(session.isPaired)")
        print("   - isWatchAppInstalled: \(session.isWatchAppInstalled)")
        print("   - isReachable: \(session.isReachable)")
        
        DispatchQueue.main.async {
            let wasReachable = self.isReachable
            self.isReachable = session.isReachable
            
            // 워치가 새로 연결되었을 때
            if !wasReachable && self.isReachable {
                print("✅ 워치 앱이 활성화됨 - 자동 동기화 시작")
                
                // 2초 후 자동 동기화 (워치 앱이 완전히 로드될 때까지 대기)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    print("🎯 워치 활성화 감지 - 음악 목록 자동 전송")
                    NotificationCenter.default.post(name: .triggerAutoSync, object: nil)
                }
            }
        }
    }
    
    #endif
    
    // MARK: - Message Handling (WatchService로 위임)
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        #if os(iOS)
        guard let action = message["action"] as? String else {
            print("⚠️ WCManager: 액션을 찾을 수 없음")
            replyHandler(["success": false])
            return
        }
        
        print(" WCManager: 워치에서 메시지 수신 - \(action)")
        print("   - 메시지 내용: \(message)")
        print("   - session.isReachable: \(session.isReachable)")
        print("   - session.activationState: \(session.activationState.rawValue)")
        
        switch action {
        case "SendRequireMusicList":
            print(" WCManager: 음악 목록 요청 수신")
            // NotificationCenter로 전달
            NotificationCenter.default.post(name: .requireMusicList, object: nil)
            replyHandler(["success": true])
            
        case "PlayToggle":
            NotificationCenter.default.post(name: .plusCount, object: nil)
            replyHandler(["success": true])
            
        case "Forward":
            NotificationCenter.default.post(name: .forward, object: nil)
            replyHandler(["success": true])
            
        case "Backward":
            NotificationCenter.default.post(name: .backward, object: nil)
            replyHandler(["success": true])
            
        case "UUIDPlay":
            if let id = message["id"] as? String {
                NotificationCenter.default.post(name: .UUIDPlay, object: id)
            }
            replyHandler(["success": true])
            
        case "MarkerPlay":
            if let index = message["index"] as? Int {
                NotificationCenter.default.post(name: .markerPlay, object: index)
            }
            replyHandler(["success": true])
            
        case "MarkerSave":
            if let index = message["index"] as? Int {
                NotificationCenter.default.post(name: .markerSave, object: index)
            }
            replyHandler(["success": true])
            
        case "MarkerDelete":
            if let index = message["index"] as? Int {
                NotificationCenter.default.post(name: .markerDelete, object: index)
            }
            replyHandler(["success": true])
            
        case "SendIncreasePlayback":
            NotificationCenter.default.post(name: .increaseSpeed, object: nil)
            replyHandler(["success": true])
            
        case "SendDecreasePlayback":
            NotificationCenter.default.post(name: .decreaseSpeed, object: nil)
            replyHandler(["success": true])
            
        case "SendOriginalPlayback":
            NotificationCenter.default.post(name: .originalSpeed, object: nil)
            replyHandler(["success": true])
            
        case "ChangeVolume":
            if let volume = message["volume"] as? Float {
                NotificationCenter.default.post(name: .changeVolume, object: volume)
            }
            replyHandler(["success": true])
            
        // 마커 수정 완료
        case "MarkerEditSuccess":
            if let forEdit = message["forEdit"] as? [Int], forEdit.count >= 2 {
                print("📥 WCManager: MarkerEditSuccess 수신 - 인덱스: \(forEdit[0]), 시간: \(forEdit[1])")
                NotificationCenter.default.post(name: .markerEditSuccess, object: forEdit)
            }
            replyHandler(["success": true])
            
        case "SendRequireCurrentState":
            print("🔄 WCManager: 워치에서 현재 상태 즉시 요청 수신")
            // PlayerViewModel에 즉시 상태 전송 요청
            NotificationCenter.default.post(name: .requireCurrentState, object: nil)
            replyHandler(["success": true])
            
        default:
            print("⚠️ WCManager: 알 수 없는 액션 - \(action)")
            replyHandler(["success": false])
        }
        #elseif os(watchOS)
        // 워치OS는 기존 로직 유지
        if let action = message["action"] as? String {
            DispatchQueue.main.async {
                switch action {
                case "SendMarkers":
                    NotificationCenter.default.post(name: .sendMarkers, object: message["markers"])
                case "SendSpeed":
                    NotificationCenter.default.post(name: .sendSpeed, object: message["speed"])
                case "SendIsPlaying":
                    NotificationCenter.default.post(name: .sendIsPlaying, object: message["isPlaying"])
                case "SendPlayingTimes":
                    NotificationCenter.default.post(name: .sendPlayingTimes, object: message["playingTimes"])
                case "SendMusicList":
                    NotificationCenter.default.post(name: .sendMusicList, object: message["musicList"])
                    print("✅ 음악 목록 수신 완료")
                case "SendMusicTitle":
                    NotificationCenter.default.post(name: .sendMusicTitle, object: message["musicTitle"])
                case "SendSystemVolume":
                    NotificationCenter.default.post(name: .sendSystemVolume, object: message["volume"])
                default:
                    break
                }
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        #endif
    }
    
    // MARK: - WCSessionDelegate (워치 앱) - ApplicationContext 처리 추가
    #if os(watchOS)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📱 WCManager: ApplicationContext 수신")
        print("   - applicationContext: \(applicationContext)")
        
        DispatchQueue.main.async {
            if let musicList = applicationContext["musicList"] as? [[String]] {
                print("✅ ApplicationContext로 음악 목록 수신: \(musicList.count)개")
                NotificationCenter.default.post(name: .sendMusicList, object: musicList)
            }
        }
    }
    #endif
    
    // MARK: - 워치 앱용 ApplicationContext 메서드들

    /// ApplicationContext에서 음악 목록을 가져옵니다
    func getMusicListFromApplicationContext() -> [[String]]? {
        let context = session.receivedApplicationContext
        
        if let musicList = context["musicList"] as? [[String]] {
            print("✅ ApplicationContext에서 음악 목록 발견: \(musicList.count)개")
            return musicList
        } else {
            print("ℹ️ ApplicationContext에 음악 목록 없음")
            return nil
        }
    }

    /// ApplicationContext에서 마지막 업데이트 시간을 가져옵니다
    func getLastUpdateTimeFromApplicationContext() -> TimeInterval? {
        let context = session.receivedApplicationContext
        return context["lastUpdated"] as? TimeInterval
    }

    /// ApplicationContext가 유효한지 확인합니다
    func isApplicationContextValid() -> Bool {
        let context = session.receivedApplicationContext
        return context["musicList"] != nil
    }
    
    // MARK: - iOS MESSAGE SENDERS (기존 메서드들 유지)
    #if os(iOS)
    func sendMarkersToWatch(_ markers: [TimeInterval]) {
        let message = [
            "action": "SendMarkers",
            "markers": markers
        ] as [String : Any]

        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("마커 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendSpeedToWatch(_ speed: Float){
        let message = [
            "action": "SendSpeed",
            "speed": speed
        ] as [String : Any]
        
        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("속도 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendIsPlayingToWatch(_ isPlaying: Bool){
        let message = [
            "action": "SendIsPlaying",
            "isPlaying": isPlaying
        ] as [String : Any]
        
        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("재생 상태 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendPlayingTimesToWatch(_ playingTimes: [TimeInterval]) {
        let message = [
            "action": "SendPlayingTimes",
            "playingTimes": playingTimes
        ] as [String : Any]

        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("재생 시간 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendMusicListToWatch(_ musics: [[String]]) {
        let message = [
            "action": "SendMusicList",
            "musicList": musics
        ] as [String : Any]

        print("📤 WCManager: 음악 목록 전송 중... (\(musics.count)개)")
        session.sendMessage(message) { _ in
            print("✅ WCManager: 음악 목록 전송 성공")
        } errorHandler: { error in
            print("❌ WCManager: 음악 목록 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendTitleToWatch(_ musictitle: String) {
        let message = [
            "action": "SendMusicTitle",
            "musicTitle": musictitle
        ] as [String : Any]

        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("제목 전송 실패: \(error.localizedDescription)")
        }
    }
    
    func sendSystemVolumeToWatch(_ volume: Float) {
        let message = [
            "action": "SendSystemVolume",
            "volume": volume
        ] as [String : Any]

        session.sendMessage(message) { _ in
        } errorHandler: { error in
            print("볼륨 전송 실패: \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: WATCH MESSAGE SENDERS (기존 메서드들 유지)
    #if os(watchOS)
    func sendPlayerLinkToIOS(_ link: String) {
        let message = [
            "action": "newPlayerLinkChosen",
            "link": link
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendPlayToggleToIOS() {
        let message = [
            "action": "PlayToggle"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendForwardToIOS() {
        let message = [
            "action": "Forward"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendBackwardToIOS() {
        let message = [
            "action": "Backward"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendIncreasePlaybackToIOS() {
        let message = [
            "action": "SendIncreasePlayback"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendDecreasePlaybackToIOS() {
        let message = [
            "action": "SendDecreasePlayback"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendOriginalPlaybackToIOS() {
        let message = [
            "action": "SendOriginalPlayback"
        ]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendRequireMusicListToIOS() {
        let message = ["action": "SendRequireMusicList"]
        
        session.sendMessage(message) { replyHandler in
            print("✅ 음악 목록 요청 성공")
        } errorHandler: { error in
            print("❌ 음악 목록 요청 실패: \(error.localizedDescription)")
        }
    }
    
    func sendUUIDPlayToIOS(_ id: String) {
        let message = [
            "action": "UUIDPlay",
            "id": id
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendRequireCurrentStateToIOS() {
        let message = ["action": "SendRequireCurrentState"]
        
        print("📤 워치: iOS에 현재 상태 요청 전송")
        session.sendMessage(message) { replyHandler in
            print("✅ 워치: 현재 상태 요청 성공")
            print("   - 응답: \(replyHandler)")
        } errorHandler: { error in
            print("❌ 워치: 현재 상태 요청 실패: \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: - Common Methods (Both iOS and watchOS)
    func sendMarkerPlayToIOS(_ index: Int) {
        let message = [
            "action": "MarkerPlay",
            "index": index
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendMarkerSaveToIOS(_ index: Int) {
        let message = [
            "action": "MarkerSave",
            "index": index
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendMarkerDeleteToIOS(_ index: Int) {
        let message = [
            "action": "MarkerDelete",
            "index": index
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendMarkerEditToIOS(forEdit: [Int]) {
        let message = [
            "action": "MarkerEdit",
            "forEdit": forEdit
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendMarkerEditSuccessToIOS(forEdit: [Int]) {
        let message = [
            "action": "MarkerEditSuccess",
            "forEdit": forEdit
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendVolumeChangeToIOS(_ volume: Float) {
        let message = [
            "action": "ChangeVolume",
            "volume": volume
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }

    private func triggerAutoSync() {
        print("🎯 triggerAutoSync 호출됨")
        
        // PlayerViewModel에 자동 동기화 요청
        NotificationCenter.default.post(name: .triggerAutoSync, object: nil)
        
        // 1초 후 재시도 (연결 안정성 확보)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🎯 triggerAutoSync 재시도")
            NotificationCenter.default.post(name: .triggerAutoSync, object: nil)
        }
    }

    // MARK: - 통합 동기화 시스템 (3단계)
    
    /// 🎯 음악 데이터 변경 시 3단계 동기화 실행
    func syncMusicDataToWatch(_ musicList: [[String]]) {
        print("🚀 3단계 동기화 시작: \(musicList.count)개 음악")
        
        // 1단계: transferUserInfo (워치 앱이 꺼져있어도 전송됨)
        sendMusicListViaTransferUserInfo(musicList)
        
        // 2단계: updateApplicationContext (워치 앱 시작 시 자동 수신)
        updateApplicationContextWithMusicData(musicList)
        
        // 3단계: 실시간 메시지 전송 (워치 앱이 실행 중일 때)
        sendRealtimeMusicUpdate(musicList)
        
        print("✅ 3단계 동기화 완료")
    }

    /// 1단계: transferUserInfo 사용
    private func sendMusicListViaTransferUserInfo(_ musicList: [[String]]) {
        let userInfo = [
            "action": "SendMusicList",
            "musicList": musicList,
            "timestamp": Date().timeIntervalSince1970,
            "syncMethod": "transferUserInfo"
        ] as [String : Any]

        print("📤 1단계: transferUserInfo로 음악 목록 전송 중... (\(musicList.count)개)")
        session.transferUserInfo(userInfo)
        print("✅ 1단계: transferUserInfo 전송 완료")
    }

    /// 2단계: updateApplicationContext 사용
    private func updateApplicationContextWithMusicData(_ musicList: [[String]]) {
        let context = [
            "musicList": musicList,
            "lastUpdated": Date().timeIntervalSince1970,
            "syncMethod": "applicationContext"
        ] as [String : Any]

        print("📤 2단계: updateApplicationContext로 음악 목록 업데이트 중...")
        
        do {
            try session.updateApplicationContext(context)
            print("✅ 2단계: updateApplicationContext 업데이트 완료")
        } catch {
            print("❌ 2단계: updateApplicationContext 업데이트 실패: \(error.localizedDescription)")
        }
    }

    /// 3단계: 실시간 메시지 전송 (워치 앱이 실행 중일 때만)
    private func sendRealtimeMusicUpdate(_ musicList: [[String]]) {
        guard session.isReachable else {
            print("⚠️ 3단계: 워치 앱이 실행 중이지 않아 실시간 전송 생략")
            return
        }

        let message = [
            "action": "SendMusicList",
            "musicList": musicList,
            "syncMethod": "realtime"
        ] as [String : Any]

        print("📤 3단계: 실시간 메시지 전송 중... (\(musicList.count)개)")
        session.sendMessage(message) { _ in
            print("✅ 3단계: 실시간 메시지 전송 성공")
        } errorHandler: { error in
            print("❌ 3단계: 실시간 메시지 전송 실패: \(error.localizedDescription)")
        }
    }

    /// 기존 sendMusicListToWatchViaUserInfo 메서드도 3단계 동기화로 업데이트
    func sendMusicListToWatchViaUserInfo(_ musics: [[String]]) {
        // 3단계 동기화 시스템 사용
        syncMusicDataToWatch(musics)
    }

}

extension Notification.Name {
    static let newLinkChosen = Notification.Name("NewLinkChosen")
    static let plusCount = Notification.Name("PlusCount")
    static let forward = Notification.Name("Forward")
    static let backward = Notification.Name("Backward")
    static let markerPlay = Notification.Name("MarkerPlay")
    static let markerSave = Notification.Name("MarkerSave")
    static let increaseSpeed = Notification.Name("SendIncreasePlayback")
    static let decreaseSpeed = Notification.Name("SendDecreasePlayback")
    static let originalSpeed = Notification.Name("SendOriginalSpeed")
    static let requireMusicList = Notification.Name("SendRequireMusicList")
    static let UUIDPlay = Notification.Name("SendUUIDPlay")
    static let markerDelete = Notification.Name("MarkerDelete")
    static let markerEdit = Notification.Name("MarkerEdit")
    static let markerEditSuccess = Notification.Name("MarkerEditSuccess")
    static let changeVolume = Notification.Name("ChangeVolume")

    static let sendMarkers = Notification.Name("SendMarkers")
    static let sendSpeed = Notification.Name("SendSpeed")
    static let sendIsPlaying = Notification.Name("SendIsPlaying")
    static let sendPlayingTimes = Notification.Name("SendPlayingTimes")
    static let sendMusicList = Notification.Name("SendMusicList")
    static let sendMusicTitle = Notification.Name("SendMusicTitle")
    static let sendSystemVolume = Notification.Name("SendSystemVolume")
    
    static let triggerAutoSync = Notification.Name("TriggerAutoSync")
    static let requireCurrentState = Notification.Name("SendRequireCurrentState")
}
