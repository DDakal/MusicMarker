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
                .environmentObject(playerViewModel)
                // Dependency Container
                .environmentObject(dependencyContainer)
                .preferredColorScheme(.dark)
//                .onAppear {
//                    // 앱 시작 시 WCManager 상태 확인
//                    print("ContentView 나타남, WCManager 상태 확인")
//                    print("   - isReachable: \(WatchConnectivityManager.shared.isReachable)")
//                }
                .onOpenURL { url in
                    urlHandler.handleIncomingURL(url)
                }
        }
        .backgroundTask(.appRefresh("com.dancingmarker.refresh")) {
            // 백그라운드에서 워치 메시지 처리
            print("백그라운드 앱 새로고침 수행됨")
        }
    }
}
