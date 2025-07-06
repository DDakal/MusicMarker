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
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
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
        .task {
            do {
                try await playerViewModel.sendMusicListToWatch(musicList)
                print("ContentView에서 워치로 음악 리스트 전송 완료")
            } catch {
                print("ContentView에서 워치 음악 리스트 전송 실패: \(error)")
            }
        }
    }
}


#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}


