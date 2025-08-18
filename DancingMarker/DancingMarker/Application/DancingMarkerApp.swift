//
//  DancingMarkerApp.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/24/24.
//

import SwiftUI
import SwiftData

@main
struct DancingMarkerApp: App {
    
    // MARK: - Dependency Container
    @StateObject private var dependencyContainer = DependencyContainer.shared
    
    // MARK: - New Architecture
    @StateObject private var playerViewModel: PlayerViewModel
    
    // MARK: - URL Handler
    private var urlHandler: URLHandler
    
    // WCManager 강제 초기화
    private let wcManager = WatchConnectivityManager.shared
    
    // MARK: - Initialization
    
    init() {
        let container = DependencyContainer.shared
        let modelContext = container.modelContainer.mainContext
        let playerVM = container.makePlayerViewModel(modelContext: modelContext)
        
        self._playerViewModel = StateObject(wrappedValue: playerVM)
        self.urlHandler = URLHandler(playerViewModel: playerVM)
        
        // WCManager 초기화 확인
        print("DancingMarkerApp: WCManager 초기화 확인")
        print("   - WCManager.shared 존재: \(WatchConnectivityManager.shared)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dependencyContainer.modelContainer)
                // New ViewModel (새로운 아키텍처)
                .environmentObject(playerViewModel)
                // Dependency Container
                .environmentObject(dependencyContainer)
                .preferredColorScheme(.dark)
                .onAppear {
                    // 앱 시작 시 WCManager 상태 확인
                    print("ContentView 나타남, WCManager 상태 확인")
                    print("   - isReachable: \(WatchConnectivityManager.shared.isReachable)")
                }
                .onOpenURL { url in
                    urlHandler.handleIncomingURL(url)
                }
        }
        .backgroundTask(.appRefresh("com.dancingmarker.refresh")) {
            // 백그라운드에서 워치 메시지 처리
            print("백그라운드 앱 새로고침 수행됨")
        }
    }
    
    // MARK: - URL Handling
    
    private func handleIncomingURL(_ url: URL) {
        print(" URL Scheme으로 앱이 열림: \(url)")
        
        // URL 스킴 확인
        guard url.scheme == "dancingmarker" else {
            print("❌ 알 수 없는 URL 스킴: \(url.scheme ?? "nil")")
            return
        }
        
        // URL 경로에 따라 처리
        switch url.host {
        case "playing":
            // PlayingView로 이동
            print(" PlayingView로 이동 요청")
            playerViewModel.handleURLNavigationToPlaying()
            
        default:
            print("❌ 알 수 없는 URL 경로: \(url.host ?? "nil")")
        }
    }
}
