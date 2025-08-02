//
//  NowPlayingView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import UIKit

struct NowPlayingView: View {
    @Environment(NavigationManager.self) var navigationManager
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        VStack {
            musicInfoSection
                .contentShape(Rectangle())
                .onTapGesture {
                    guard playerViewModel.currentMusic != nil else { return }
                    navigationManager.push(to: .playing)
                }
                .padding(.vertical, 8)
            
            // 진행률 슬라이더
            ProgressSliderView()
                .font(.caption)
            
            // 재생 제어 버튼들 (미니 버전)
            miniPlaybackControls
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var musicInfoSection: some View {
        HStack(spacing: 10) {
            // 앨범아트
            albumArtView
            
            // 음원 정보 (TextMarquee)
            if let music = playerViewModel.currentMusic {
                TextMarquee(
                    title: music.title,
                    artist: music.artist,
                    titleFont: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize),
                    artistFont: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                )
                .overlay(
                    textMarqueeOverlay(title: music.title, artist: music.artist)
                )
            } else {
                Spacer()
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var albumArtView: some View {
        if let music = playerViewModel.currentMusic,
           let albumArtData = music.albumArt, 
           let albumArt = UIImage(data: albumArtData) {
            Image(uiImage: albumArt)
                .resizable()
                .frame(width: 66, height: 66)
                .cornerRadius(13)
        } else {
            RoundedRectangle(cornerRadius: 13)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 66, height: 66)
                .overlay {
                    Image(systemName: "music.note")
                        .resizable()
                        .padding()
                        .scaledToFit()
                        .foregroundStyle(.gray)
                }
        }
    }
    
    @ViewBuilder
    private var miniPlaybackControls: some View {
        HStack(alignment: .center, spacing: 50) {
            // 5초 뒤로
            playbackButton(
                systemName: "gobackward.5",
                size: 60,
                iconSize: 36,
                action: {
                    Task {
                        do {
                            try await playerViewModel.skipBackward()
                        } catch {
                            print("5초 뒤로 이동 중 오류: \(error)")
                        }
                    }
                }
            )
            .padding(.leading, 28)
            
            // 재생/일시정지
            playbackButton(
                systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill",
                size: 80,
                iconSize: 30,
                action: {
                    Task {
                        await playerViewModel.togglePlayback()
                    }
                }
            )
            
            // 5초 앞으로
            playbackButton(
                systemName: "goforward.5",
                size: 60,
                iconSize: 36,
                action: {
                    Task {
                        do {
                            try await playerViewModel.skipForward()
                        } catch {
                            print("5초 앞으로 이동 중 오류: \(error)")
                        }
                    }
                }
            )
            .padding(.trailing, 28)
        }
    }
    
    @ViewBuilder
    private func playbackButton(systemName: String, size: CGFloat, iconSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .foregroundStyle(.buttonDarkGray)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: systemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize)
                        .foregroundStyle(.white)
                }
        }
    }
    
    // MARK: - TextMarquee Overlay
    
    @ViewBuilder
    private func textMarqueeOverlay(title: String, artist: String) -> some View {
            GeometryReader { geo in
                VStack(spacing: 12) {
                    // Title Overlay
                    HStack(spacing: 0) {
                        if needsMask(for: title, availableWidth: geo.size.width, font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize)) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.nowPlayingGray, Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 10)
                        }
                        
                        Spacer()
                            .frame(width: geo.size.width + 10)
                        
                        if needsMask(for: title, availableWidth: geo.size.width, font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize)) {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0),
                                    .init(color: Color.nowPlayingGray.opacity(0.5), location: 0.1),
                                    .init(color: Color.nowPlayingGray, location: 0.2),
                                    .init(color: Color.nowPlayingGray, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                        }
                    }
                    .frame(height: geo.size.height / 2)
                    .offset(x: -4)
                    
                    // Artist Overlay
                    HStack(spacing: 0) {
                        if needsMask(for: artist, availableWidth: geo.size.width, font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize)) {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.nowPlayingGray, Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 10)
                        }
                        
                        Spacer()
                            .frame(width: geo.size.width + 10)
                        
                        if needsMask(for: artist, availableWidth: geo.size.width, font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize)) {
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0),
                                    .init(color: Color.nowPlayingGray.opacity(0.5), location: 0.1),
                                    .init(color: Color.nowPlayingGray, location: 0.2),
                                    .init(color: Color.nowPlayingGray, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                        }
                    }
                    .frame(height: geo.size.height / 2)
                    .offset(x: -4)
                }
            }
        }

    // MARK: - Text Length Check
    
    private func needsMask(for text: String, availableWidth: CGFloat, font: UIFont) -> Bool {
        let textWidth = measureTextWidth(text, font: font)
        // availableWidth에서 약간의 여유(10포인트)를 뺀 값보다 텍스트가 길면 마스킹이 필요함
        return textWidth > (availableWidth - 10)
    }

    // MARK: - Text Width Measurement
    
    private func measureTextWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }
}

#Preview {
    NowPlayingView()
        .preferredColorScheme(.dark)
}
