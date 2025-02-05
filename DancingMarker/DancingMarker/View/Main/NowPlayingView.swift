//
//  NowPlayingView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI

struct NowPlayingView: View {
    @Environment(NavigationManager.self) var navigationManager
    @EnvironmentObject var playerModel: PlayerModel
    
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                if let music = playerModel.music {
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
                                    .foregroundColor(.gray)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(music.title)
                            .font(.title3)
                            .bold()
                        Text(music.artist)
                            .font(.body)
                    }
                    .lineLimit(1)
                    Spacer()
                    
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
                                .foregroundColor(.gray)
                        }
                    Spacer()
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard playerModel.music != nil else {
                    return
                }
                navigationManager.push(to: .playing)
            }

            .padding(.bottom, 8)
            
            /// 슬라이더
            VStack() {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundColor(.inactiveGray)
                        
                        Rectangle()
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width * CGFloat(playerModel.progress), height: geometry.size.height)
                    }
                    .cornerRadius(12)
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            DispatchQueue.main.async {
                                let newProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                                playerModel.progress = newProgress
                                let newTime = newProgress * playerModel.duration
                                playerModel.currentTime = newTime
                                playerModel.formattedProgress = playerModel.formattedTime(newTime)
                                playerModel.updateAudioPlayer(with: newTime)
                            }
                        }))
                }
                .frame(height: 5)
                .padding(.bottom, 3)
                
                HStack {
                    Text("\(playerModel.formattedProgress)")
                    Spacer()
                    Text("\(playerModel.formattedDuration)")
                }
            }
            
            /// 제어 버튼
            HStack(alignment: .center, spacing: 50) {  
                Circle()
                    .foregroundStyle(.buttonDarkGray)
                    .frame(width: 60)
                    .overlay(
                        Button(action: {
                            playerModel.backward5Sec()
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
                            playerModel.togglePlayback()
                        }) {
                            Image(systemName: playerModel.isPlaying ? "pause.fill" : "play.fill")
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
                            playerModel.forward5Sec()
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
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
        
    }
}
