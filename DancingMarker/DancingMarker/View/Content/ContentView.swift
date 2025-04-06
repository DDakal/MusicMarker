//
//  ContentView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/24/24.
// 

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationManager = NavigationManager()
    @State private var showMusicList = false
    @State private var currentView: PathType? = nil
    @Query var musicList: [Music] = []
    @EnvironmentObject var playerModel: PlayerModel
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
                MusicListView()
                
            }
            .navigationDestination(for: PathType.self) { pathType in
                pathType.NavigatingView()
            }
            
        }
        .environment(navigationManager)
        .onAppear {
            playerModel.sendMusicListToWatch(with: musicList)
        }
    }
}


#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}


