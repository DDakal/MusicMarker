//
//  NavigationManager.swift
//  WatchDancingMarker Watch App
//
//  Created by 변준섭 on 6/25/24.
//

import SwiftUI

enum WatchPathType: Hashable {
    case musicList
    case playing
}

extension WatchPathType {
    @ViewBuilder
    func NavigatingView() -> some View {
        switch self {
        case .musicList:
            WatchMusicListView()
            
        case .playing:
            WatchPlayingView()
        }
    }
}

@Observable
class WatchNavigationManager {
    var path: [WatchPathType]
    init(
        path: [WatchPathType] = []
    ){
        self.path = path
    }
}

extension WatchNavigationManager {
    func push(to pathType: WatchPathType) {
        path.append(pathType)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func pop(to pathType: WatchPathType) {
        guard let lastIndex = path.lastIndex(of: pathType) else { return }
        path.removeLast(path.count - (lastIndex + 1))
    }
}

