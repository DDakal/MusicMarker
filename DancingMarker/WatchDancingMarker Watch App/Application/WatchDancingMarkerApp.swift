//
//  WatchDancingMarkerApp.swift
//  WatchDancingMarker Watch App
//
//  Created by 변준섭 on 6/24/24.
//

import SwiftUI
import SwiftData
import Mixpanel

@main
struct WatchDancingMarker_Watch_AppApp: App {
    
    @StateObject var viewModel = WatchViewModel(connectivityManager: WatchConnectivityManager())
    
    init() {
        if let token = Bundle.main.object(forInfoDictionaryKey: "TOKEN_KEY") as? String {
            Mixpanel.initialize(token: token)
        } else {
            print("Error: Mixpanel token not found in Info.plist")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            WatchMusicListView()
                .environmentObject(viewModel)
                .accentColor(.accent)
        }
    }
}
