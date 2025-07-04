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
    
    static var shared = WatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // 로그 제거
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        // 로그 제거
    }
    #endif
    
    // MARK: MESSAGE RECEIVER
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        #if os(iOS)
        guard let action = message["action"] as? String else {
            replyHandler(["success": false])
            return
        }
        
        print("WCManager: 워치에서 메시지 수신: \(action)")
        
        // WatchService로 위임 (우선순위)
        let wasHandled = WatchService.shared?.handleReceivedWatchMessage(action: action, message: message) ?? false
        
        if wasHandled {
            print("WCManager: WatchService에서 처리됨")
            replyHandler(["success": true])
        } else {
            print("WCManager: NotificationCenter로 폴백")
            handleMessageWithNotificationCenter(action: action, message: message)
            replyHandler(["success": true])
        }
        
        #elseif os(watchOS)
        // 워치OS 메시지 수신 처리 (기존 로직 유지하되 로그 정리)
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
    
    // MARK: - Private Helper Methods
    
    private func handleMessageWithNotificationCenter(action: String, message: [String: Any]) {
        let notificationName: Notification.Name
        var object: Any? = nil
        
        switch action {
        case "SendRequireMusicList":
            notificationName = .requireMusicList
        case "newPlayerLinkChosen":
            notificationName = .newLinkChosen
            object = message["link"]
        case "PlusCount":
            notificationName = .plusCount
        case "Forward":
            notificationName = .forward
        case "Backward":
            notificationName = .backward
        case "MarkerPlay":
            notificationName = .markerPlay
            object = message["index"]
        case "MarkerSave":
            notificationName = .markerSave
            object = message["index"]
        case "SendIncreasePlayback":
            notificationName = .increaseSpeed
        case "SendDecreasePlayback":
            notificationName = .decreaseSpeed
        case "SendOriginalPlayback":
            notificationName = .originalSpeed
        case "UUIDPlay":
            notificationName = .UUIDPlay
            object = message["id"]
        case "MarkerDelete":
            notificationName = .markerDelete
            object = message["index"]
        case "MarkerEdit":
            notificationName = .markerEdit
            object = message["forEdit"]
        case "MarkerEditSuccess":
            notificationName = .markerEditSuccess
            object = message["forEdit"]
        case "ChangeVolume":
            notificationName = .changeVolume
            object = message["volume"]
        default:
            return
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: notificationName, object: object)
        }
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
    
    // MARK: WATCH MESSAGE SENDERS (기존 메서드들 유지하되 로그 정리)
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
}