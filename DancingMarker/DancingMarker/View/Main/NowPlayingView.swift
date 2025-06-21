//
//  NowPlayingView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI

struct NowPlayingView: View {
    @Environment(NavigationManager.self) var navigationManager
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                if let music = playerViewModel.currentMusic {
                    if let albumArtData = music.albumArt, let albumArt = UIImage(data: albumArtData) {
                        Image(uiImage: albumArt)
                            .resizable()
                            .frame(width: 66, height: 66)
                            .cornerRadius(13)
                    } else {
                        RoundedRectangle(cornerRadius: 13)
                            .fill(.textLightGray)
                            .frame(width: 66, height: 66)
                            .overlay {
                                Image(systemName: "music.note")
                                    .resizable()
                                    .padding()
                                    .scaledToFit()
                                    .foregroundStyle(.gray)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TextMarquee(
                            title: music.title, 
                            artist: music.artist, 
                            titleFont: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize), 
                            artistFont: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                        )
                    }
                    .overlay(
                        overlayForMarquee(title: music.title, artist: music.artist)
                    )
                    
                } else {
                    // 음악이 없는 경우
                    RoundedRectangle(cornerRadius: 13)
                        .fill(.textLightGray)
                        .frame(width: 66, height: 66)
                        .overlay {
                            Image(systemName: "music.note")
                                .resizable()
                                .padding()
                                .scaledToFit()
                                .foregroundStyle(.gray)
                        }
                    Spacer()
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard playerViewModel.currentMusic != nil else {
                    return
                }
                navigationManager.push(to: .playing)
            }
            .padding(.vertical, 8)
            
            /// 슬라이더
            VStack() {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundStyle(.inactiveGray)
                        
                        Rectangle()
                            .foregroundStyle(.white)
                            .frame(width: geometry.size.width * CGFloat(playerViewModel.progress), height: geometry.size.height)
                    }
                    .cornerRadius(12)
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            // ✅ 드래그 시작 시 타이머 업데이트 중단
                            if !playerViewModel.isDragging {
                                playerViewModel.setDragging(true)
                            }
                            
                            let newProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                            let newTime = newProgress * playerViewModel.duration
                            
                            // ✅ UI만 즉시 업데이트
                            playerViewModel.currentTime = newTime
                            playerViewModel.updateProgress()
                            playerViewModel.updateFormattedTime()
                        })
                        .onEnded({ value in
                            // ✅ 드래그 종료 시 실제 seek 수행
                            let newProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                            let newTime = newProgress * playerViewModel.duration
                            
                            Task {
                                do {
                                    try await playerViewModel.seek(to: newTime)
                                    playerViewModel.setDragging(false)
                                } catch {
                                    print("시간 이동 중 오류: \(error)")
                                    playerViewModel.setDragging(false)
                                }
                            }
                        }))
                }
                .frame(height: 8)
                .padding(.bottom, 3)
                
                HStack {
                    Text("\(playerViewModel.formattedProgress)")
                    Spacer()
                    Text("\(playerViewModel.formattedDuration)")
                }
                .font(.caption)
            }
            
            /// 제어 버튼
            HStack(alignment: .center, spacing: 50) {  
                Circle()
                    .foregroundStyle(.buttonDarkGray)
                    .frame(width: 60)
                    .overlay(
                        Button(action: {
                            Task {
                                do {
                                    try await playerViewModel.skipBackward()
                                } catch {
                                    print("5초 뒤로 이동 중 오류: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: "gobackward.5")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36)
                                .foregroundStyle(.white)
                        }
                    )
                    .padding(.leading, 28)
                
                Circle()
                    .foregroundStyle(.buttonDarkGray)
                    .frame(width: 80)
                    .overlay(
                        Button(action: {
                            Task {
                                await handlePlayPauseToggle()
                            }
                        }) {
                            Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)
                                .foregroundStyle(.white)
                        }
                    )
                
                Circle()
                    .foregroundStyle(.buttonDarkGray)
                    .frame(width: 60)
                    .overlay(
                        Button(action: {
                            Task {
                                do {
                                    try await playerViewModel.skipForward()
                                } catch {
                                    print("5초 앞으로 이동 중 오류: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: "goforward.5")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36)
                                .foregroundStyle(.white)
                        }
                    )
                    .padding(.trailing, 28)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Private Methods
    
    /// 재생/일시정지 토글 처리
    private func handlePlayPauseToggle() async {
        do {
            if playerViewModel.isPlaying {
                playerViewModel.pauseMusic()
            } else {
                if playerViewModel.currentMusic != nil {
                    try await playerViewModel.resumeMusic()
                }
            }
        } catch {
            print("재생/일시정지 토글 중 오류: \(error)")
        }
    }
    
    // MARK: - Mask Logic
    private func overlayForMarquee(title: String, artist: String) -> some View {
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
