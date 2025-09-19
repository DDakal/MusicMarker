//
//  WatchPlaybackControls.swift
//  WatchDancingMarker Watch App
//
//  Created by Woowon Kang on 8/5/25.
//

import SwiftUI

struct WatchPlaybackControls: View {
    let isPlaying: Bool
    let progress: Double
    let onBackward: () async throws -> Void
    let onPlayToggle: () async -> Void
    let onForward: () async throws -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            // 뒤로 가기 버튼
            BackwardButton(onTap: onBackward)
            
            Spacer()
            
            // 재생/일시정지 버튼 (프로그레스 포함)
            PlayPauseButton(
                isPlaying: isPlaying,
                progress: progress,
                onTap: onPlayToggle
            )
            
            Spacer()
            
            // 앞으로 가기 버튼
            ForwardButton(onTap: onForward)
            
            Spacer()
        }
    }
}

// MARK: - Sub Components

struct BackwardButton: View {
    let onTap: () async throws -> Void
    
    var body: some View {
        Group {
            if #available(watchOS 26.0, *) {
                Button {
                    Task {
                        do {
                            try await onTap()
                        } catch {
                            // 에러 처리
                        }
                    }
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title3)
                        .frame(width: 34, height: 34)
                        .glassEffect()
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
            } else {
                Circle()
                    .fill(.gray.opacity(0.2))
                    .cornerRadius(4)
                    .frame(height: 35)
                    .overlay(
                        Button(action: {
                            Task {
                                do {
                                    try await onTap()
                                } catch {
                                    print("뒤로 이동 중 오류: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: "gobackward.5")
                                .resizable()
                                .frame(width: 20, height: 21)
                        }
                        .frame(width: 34, height: 35)
                        .buttonStyle(PlainButtonStyle())
                    )
            }
        }
    }
}

//struct PlayPauseButton: View {
//    let isPlaying: Bool
//    let progress: Double
//    let onTap: () async -> Void
//
//    var body: some View {
//        ZStack {
//            Circle()
//                .fill(.gray.opacity(0.2))
//                .frame(height: 44)
//                .overlay(
//                    Button(action: {
//                        Task {
//                            await onTap()
//                        }
//                    }) {
//                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
//                            .resizable()
//                            .frame(width: 18, height: 18)
//                    }
//                    .frame(width: 44, height: 44)
//                    .buttonBorderShape(.circle)
//                    .buttonStyle(PlainButtonStyle())
//                )
//
//            CircleProgressView(progress: progress)
//                .frame(width: 42, height: 42)
//        }
//    }
//}

struct PlayPauseButton: View {
    let isPlaying: Bool
    let progress: Double
    let onTap: () async -> Void
    
    // 레거시 코드 남겨둠
    var body: some View {
        ZStack {
            if #available(watchOS 26.0, *) {
                Circle()
                    .fill(.clear)
                    .frame(height: 44)
                    .glassEffect()
                    .overlay(
                        Button(action: {
                            Task {
                                await onTap()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                            .frame(width: 44, height: 44)
                            .buttonBorderShape(.circle)
                            
                    )
                    .buttonStyle(.plain)
                
                
                CircleProgressView(progress: progress)
                    .frame(width: 42, height: 42)
            } else {
                Circle()
                    .fill(.gray.opacity(0.2))
                    .frame(height: 44)
                    .overlay(
                        Button(action: {
                            Task {
                                await onTap()
                            }
                        }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .frame(width: 18, height: 18)
                        }
                            .frame(width: 44, height: 44)
                            .buttonBorderShape(.circle)
                            .buttonStyle(PlainButtonStyle())
                    )
                
                
                CircleProgressView(progress: progress)
                    .frame(width: 42, height: 42)
            }
        }
    }
}

struct ForwardButton: View {
    let onTap: () async throws -> Void
    
    var body: some View {
        Group {
            if #available(watchOS 26.0, *) {
                Button {
                    Task {
                        do {
                            try await onTap()
                        } catch {
                            // 에러 처리
                        }
                    }
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.title3)
                        .frame(width: 34, height: 34)
                        .glassEffect()
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
            } else {
                Circle()
                    .fill(.gray.opacity(0.2))
                    .cornerRadius(4)
                    .frame(height: 35)
                    .overlay(
                        Button(action: {
                            Task {
                                do {
                                    try await onTap()
                                } catch {
                                    print("앞으로 이동 중 오류: \(error)")
                                }
                            }
                        }) {
                            Image(systemName: "goforward.5")
                                .resizable()
                                .frame(width: 20, height: 21)
                        }
                        .frame(width: 34, height: 35)
                        .buttonStyle(PlainButtonStyle())
                    )
            }
        }
    }
}
