////
////  ContentView.swift
////  WatchDancingMarker Watch App
////
////  Created by 변준섭 on 6/24/24.
////
//
//import SwiftUI
//
//struct ContentView: View {
//    
//    @State private var navigationManager = WatchNavigationManager()
//    
//    var body: some View {
//        ZStack{
//            NavigationStack(path: $navigationManager.path) {
////                VStack {
////                    Text("여기는 실제로 보이지 않는 화면입니다.")
////                    Button("Go to MusicListView") {
////                        navigationManager.push(to: .musicList)
////                    }
////                }
//                .navigationDestination(for: WatchPathType.self) { pathType in
//                    pathType.NavigatingView()
//                }
//            }
//            .environment(navigationManager)
//        }
//        
//        
//    }
//}
//
//#Preview {
//    ContentView()
//}
//
