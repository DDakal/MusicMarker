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
    let onBackward: () async throws -> Void      // ✅ iOS 패턴
    let onPlayToggle: () async -> Void           // ✅ iOS 패턴  
    let onForward: () async throws -> Void       // ✅ iOS 패턴
    
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
        Circle()
            .fill(.gray.opacity(0.2))           // 🎨 기존 색상 유지
            .cornerRadius(4)                    // 🎨 기존 스타일 유지
            .frame(height: 35)
            .overlay(
                Button(action: {
                    Task {                      // ✅ iOS 패턴: Task 블록
                        do {
                            try await onTap()   // ✅ iOS 패턴: 에러 처리
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

struct PlayPauseButton: View {
    let isPlaying: Bool
    let progress: Double
    let onTap: () async -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.gray.opacity(0.2))       // 🎨 기존 색상 유지
                .frame(height: 44)
                .overlay(
                    Button(action: {
                        Task {                  // ✅ iOS 패턴: Task 블록
                            await onTap()       // ✅ iOS 패턴: async 호출
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

struct ForwardButton: View {
    let onTap: () async throws -> Void
    
    var body: some View {
        Circle()
            .fill(.gray.opacity(0.2))           // 🎨 기존 색상 유지
            .cornerRadius(4)                    // 🎨 기존 스타일 유지
            .frame(height: 35)
            .overlay(
                Button(action: {
                    Task {                      // ✅ iOS 패턴: Task 블록
                        do {
                            try await onTap()   // ✅ iOS 패턴: 에러 처리
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
