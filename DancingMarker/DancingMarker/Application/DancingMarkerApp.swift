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
    
    // MARK: - Initialization
    
    init() {
        let container = DependencyContainer.shared
        // ModelContext를 컨테이너에서 가져와서 전달
        let modelContext = container.modelContainer.mainContext
        self._playerViewModel = StateObject(wrappedValue: container.makePlayerViewModel(modelContext: modelContext))
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
        }
    }
}
