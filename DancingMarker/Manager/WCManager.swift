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
        #if os(iOS)
        print("ACTIVATED ON IOS")
        #elseif os(watchOS)
        print("ACTIVATED ON WATCHOS")
        #endif
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
                   self.isReachable = session.isReachable
                   print("Reachability changed: \(self.isReachable)")
                   if !self.isReachable {
                       print("Session is not reachable, attempting to reactivate...")
                       self.session.activate() // 재활성화 시도
                   }
               }
    }
    
    #if os(iOS)
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive: \(session.activationState.rawValue)")
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        print("Session watch state did change: \(session.activationState.rawValue)")
    }
    
    #endif
    
    // MARK: MESSAGE RECEIVER
    
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String : Any],
        replyHandler: @escaping ([String : Any]) -> Void
    ) {
        #if os(iOS)
        if let action = message["action"] as? String,
           action == "PlayToggle" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .plusCount,
                    object: nil
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "Forward" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .forward,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        
        if let action = message["action"] as? String,
           action == "Backward" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .backward,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendIncreasePlayback" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .increaseSpeed,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendDecreasePlayback" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .decreaseSpeed,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendOriginalPlayback" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .originalSpeed,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "MarkerPlay" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerPlay,
                    object: message["index"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "MarkerSave" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerSave,
                    object: message["index"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "UUIDPlay" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .UUIDPlay,
                    object: message["id"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "MarkerDelete" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerDelete,
                    object: message["index"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "MarkerEdit" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerEdit,
                    object: message["forEdit"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "MarkerEditSuccess" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .markerEditSuccess,
                    object: message["forEdit"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendRequireMusicList" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .requireMusicList,
                    object: nil
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "ChangeVolume" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .changeVolume,
                    object: message["volume"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        
        
        
        
        #elseif os(watchOS)
        
        if let action = message["action"] as? String,
           action == "SendMarkers" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendMarkers,
                    object: message["markers"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendSpeed" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendSpeed,
                    object: message["speed"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendIsPlaying" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendIsPlaying,
                    object: message["isPlaying"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendPlayingTimes" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendPlayingTimes,
                    object: message["playingTimes"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendMusicList" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendMusicList,
                    object: message["musicList"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendMusicTitle" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendMusicTitle,
                    object: message["musicTitle"]
                )
                replyHandler(["success": true])
                print("성공!")
            }
        } else {
            replyHandler(["success": false])
        }
        
        if let action = message["action"] as? String,
           action == "SendSystemVolume" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .sendSystemVolume,
                    object: message["volume"]
                )
                replyHandler(["success": true])
            }
        } else {
            replyHandler(["success": false])
        }
        #endif
    }
    
    
    
    #if os (iOS)
    // MARK: iOS MESSAGE SENDERS
    func sendMarkersToWatch(_ markers: [TimeInterval]) {
        let message = [
            "action": "SendMarkers",
            "markers": markers
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendSpeedToWatch(_ speed: Float){
        let message = [
            "action": "SendSpeed",
            "speed": speed
        ] as [String : Any]
        
        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendIsPlayingToWatch(_ isPlaying: Bool){
        let message = [
            "action": "SendIsPlaying",
            "isPlaying": isPlaying
        ] as [String : Any]
        
        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendPlayingTimesToWatch(_ playingTimes: [TimeInterval]) {
        let message = [
            "action": "SendPlayingTimes",
            "playingTimes": playingTimes
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendMusicListToWatch(_ musics: [[String]]) {
        let message = [
            "action": "SendMusicList",
            "musicList": musics
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendTitleToWatch(_ musictitle: String) {
        let message = [
            "action": "SendMusicTitle",
            "musicTitle": musictitle
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }
    
    func sendSystemVolumeToWatch(_ volume: Float) {
        let message = [
            "action": "SendSystemVolume",
            "volume": volume
        ] as [String : Any]

        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
        }
    }

    #endif
    
    
    
    
    // MARK: WATCH MESSAGE RECIEVERS
    
    // MARK: WATCH MESSAGE SENDERS
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
        let message = [
            "action": "SendRequireMusicList"
        ]
        
        session.sendMessage(message) { replyHandler in
            print(replyHandler)
        } errorHandler: { error in
            print(error.localizedDescription)
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
