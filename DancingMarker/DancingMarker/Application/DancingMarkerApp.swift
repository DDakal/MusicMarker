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
    
    // WCManager 강제 초기화
    private let wcManager = WatchConnectivityManager.shared
    
    // MARK: - Initialization
    
    init() {
        let container = DependencyContainer.shared
        // ModelContext를 컨테이너에서 가져와서 전달
        let modelContext = container.modelContainer.mainContext
        self._playerViewModel = StateObject(wrappedValue: container.makePlayerViewModel(modelContext: modelContext))
        
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
        }
        .backgroundTask(.appRefresh("com.dancingmarker.refresh")) {
            // 백그라운드에서 워치 메시지 처리
            print("백그라운드 앱 새로고침 수행됨")
        }
    }
}
