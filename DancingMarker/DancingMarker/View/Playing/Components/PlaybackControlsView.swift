//
//  PlaybackControlsView.swift
//  DancingMarker
//
//  Created by Woowon Kang on 8/1/25.
//

import SwiftUI

struct PlaybackControlsView: View {
    let isPlaying: Bool
    let onPlayPause: () async -> Void
    let onSkipBackward: () async throws -> Void
    let onSkipForward: () async throws -> Void
    
    var body: some View {
        HStack {
            // 5초 뒤로
            Circle()
                .foregroundStyle(.buttonDarkGray)
                .frame(width: 60)
                .overlay(
                    Button(action: {
                        Task {
                            do {
                                try await onSkipBackward()
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
            
            Spacer()
            
            // 재생/일시정지
            Circle()
                .foregroundStyle(.buttonDarkGray)
                .frame(width: 80)
                .overlay(
                    Button(action: {
                        Task {
                            await onPlayPause()
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 30)
                )
            
            Spacer()
            
            // 5초 앞으로
            Circle()
                .foregroundStyle(.buttonDarkGray)
                .frame(width: 60)
                .overlay(
                    Button(action: {
                        Task {
                            do {
                                try await onSkipForward()
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
        }
    }
}
