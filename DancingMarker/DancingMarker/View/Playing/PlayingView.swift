//
//  PlayingView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI

struct PlayingView: View {
    @Environment(NavigationManager.self) var navigationManager
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        VStack {
            // 음원 정보
            MusicInfoView(music: playerViewModel.currentMusic)
            
            // 마커 리스트  
            MarkerListView()
            
            // 배속 제어
            SpeedControlView(
                currentRate: playerViewModel.playbackRate,
                onDecrease: playerViewModel.decreasePlaybackSpeed,
                onReset: playerViewModel.resetPlaybackSpeed,
                onIncrease: playerViewModel.increasePlaybackSpeed
            )
            .padding(.bottom, 30)
            .padding(.top, 59)
            
            // 진행률 슬라이더
            ProgressSliderView()
                .padding(.bottom, 40)
            
            // 재생 제어 버튼들
            PlaybackControlsView(
                isPlaying: playerViewModel.isPlaying,
                onPlayPause: playerViewModel.togglePlayback,
                onSkipBackward: playerViewModel.skipBackward,
                onSkipForward: playerViewModel.skipForward
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .enableSwipeBack()
                .apply { view in
            if #available(iOS 26.0, *) {
                // ✅ iOS 26: 기본 뒤로가기 버튼 사용 (자동 Liquid Glass)
                view
            } else {
                view
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .bold()
                                Text("Local_Back")
                            }
                            .foregroundStyle(.accent)
                            .onTapGesture {
                                navigationManager.pop()
                            }
                        }
                    }
            }
        }
    }
    
}

#Preview {
    PlayingView()
        .preferredColorScheme(.dark)
}
