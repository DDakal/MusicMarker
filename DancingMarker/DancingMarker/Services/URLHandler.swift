//
//  URLHandler.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/18/25.
//

import Foundation

/// 앱의 URL Scheme 처리를 담당하는 서비스
final class URLHandler {
    
    private weak var playerViewModel: PlayerViewModel?
    
    init(playerViewModel: PlayerViewModel) {
        self.playerViewModel = playerViewModel
    }
    
    /// URL을 처리하는 메인 메서드
    func handleIncomingURL(_ url: URL) {
        print("�� URL Scheme으로 앱이 열림: \(url)")
        
        // URL 스킴 확인
        guard url.scheme == "dancingmarker" else {
            print("❌ 알 수 없는 URL 스킴: \(url.scheme ?? "nil")")
            return
        }
        
        // URL 경로에 따라 처리
        switch url.host {
        case "playing":
            handlePlayingURL(url)
            
        default:
            print("❌ 알 수 없는 URL 경로: \(url.host ?? "nil")")
        }
    }
    
    // MARK: - Private Methods
    
    /// PlayingView로 이동하는 URL 처리
    private func handlePlayingURL(_ url: URL) {
        print("�� PlayingView로 이동 요청")
        
        guard let playerViewModel = playerViewModel else {
            print("❌ PlayerViewModel이 없음")
            return
        }
        
        // 음원 ID가 포함되어 있는지 확인
        if let musicId = extractMusicId(from: url) {
            print("🎵 음원 ID \(musicId)로 PlayingView 이동 요청")
            // TODO: 특정 음원으로 변경하는 로직 추가
        }
        
        Task { @MainActor in
            playerViewModel.handleURLNavigationToPlaying()
        }
    }
    
    /// URL에서 음원 ID 추출
    private func extractMusicId(from url: URL) -> String? {
        let pathComponents = url.pathComponents
        // "/playing/musicId" 형태에서 musicId 추출
        if pathComponents.count > 2 && pathComponents[1] == "playing" {
            return pathComponents[2]
        }
        return nil
    }
}

// MARK: - URL Scheme Constants

extension URLHandler {
    
    /// 앱의 URL Scheme
    static let scheme = "dancingmarker"
    
    /// URL 생성 헬퍼 메서드들
    struct URLBuilder {
        /// PlayingView로 이동하는 URL 생성
        static func playingURL() -> URL {
            return URL(string: "\(URLHandler.scheme)://playing")!
        }
        
        /// 특정 음원의 PlayingView로 이동하는 URL 생성
        static func playingURL(musicId: String) -> URL {
            return URL(string: "\(URLHandler.scheme)://playing/\(musicId)")!
        }
    }
}
