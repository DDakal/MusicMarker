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
    var modelContainer: ModelContainer = {
            let schema = Schema([Music.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
    
    @StateObject var viewModel = PlayerModel(connectivityManager: WatchConnectivityManager())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environmentObject(viewModel)
                .preferredColorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
        }
    }
}

