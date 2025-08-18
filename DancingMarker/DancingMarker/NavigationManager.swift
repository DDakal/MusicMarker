//
//  NavigationManager.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI

enum PathType: Hashable {
    case musicList
    case playing
    case nowplaying
}

extension PathType {
    @ViewBuilder
    func NavigatingView() -> some View {
        switch self {
        case .musicList:
            MusicListView()
        case .playing:
            PlayingView()
        case .nowplaying:
            NowPlayingView()
        }
    }
}

@Observable
class NavigationManager {
    var path: [PathType]
    
    init(path: [PathType] = []) {
        self.path = path
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .navigateToPlayingFromURL,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleURLNavigationToPlaying()
        }
    }
    
    private func handleURLNavigationToPlaying() {
        print(" NavigationManager: URL을 통해 PlayingView로 이동")
        
        // 기존 경로를 모두 제거하고 PlayingView로 이동
        path.removeAll()
        path.append(.playing)
    }
}

extension NavigationManager {
    func push(to pathType: PathType) {
        path.append(pathType)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func pop(to pathType: PathType) {
        guard let lastIndex = path.lastIndex(of: pathType) else { return }
        path.removeLast(path.count - (lastIndex + 1))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// URL을 통해 PlayingView로 이동하기 위한 알림
    static let navigateToPlayingFromURL = Notification.Name("navigateToPlayingFromURL")
}

