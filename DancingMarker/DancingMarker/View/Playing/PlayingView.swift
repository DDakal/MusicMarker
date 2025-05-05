//
//  PlayingView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import AVFoundation

struct PlayingView: View {
    @Environment(NavigationManager.self) var navigationManager
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playerModel: PlayerModel

    var body: some View {
        VStack {
            /// 음원 정보
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
                    Spacer()
                } else {
                    Text("선택된 음악이 없습니다.")
                }
            }
            .padding(.vertical, 12)
            
            /// 마커 리스트
            MarkerListView()
            
            /// 배속 버튼
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 360, height: 50)
                .foregroundStyle(.buttonDarkGray)
                .overlay(
                    HStack(spacing: 10) {
                        Button(action: {
                            playerModel.decreasePlaybackRate()
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 30, height: 30)
                                .foregroundStyle(playerModel.playbackRate <= 0.5 ? .inactiveGray : .white)
                        }
                        .padding(10)
                        .disabled(playerModel.playbackRate <= 0.5)
                        Spacer()
                        
                        Button(action: {
                            playerModel.playbackRate = 1.0
                            playerModel.updateAudioPlayer()
                        }) {
                            Text(String(format: "x%.1f", playerModel.playbackRate))
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        
                        Button(action: {
                            playerModel.increasePlaybackRate()
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                                .foregroundStyle(playerModel.playbackRate >= 1.5 ? .inactiveGray : .white)
                        }
                        .padding(10)
                        .disabled(playerModel.playbackRate >= 1.5)
                    }
                    .padding(.horizontal, 20)
                )
                .padding(.bottom, 30)
                .padding(.top, 59)
            
            /// 슬라이더
            VStack() {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .foregroundStyle(.inactiveGray)
                        
                        Rectangle()
                            .foregroundStyle(.white)
                            .frame(width: geometry.size.width * CGFloat(playerModel.progress), height: geometry.size.height)
                    }
                    .cornerRadius(12)
                    .background(Color.red.opacity(0.2))
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
                .frame(height: 8)
                .padding(.bottom, 3)
                
                HStack {
                    Text("\(playerModel.formattedProgress)")
                    Spacer()
                    Text("\(playerModel.formattedDuration)")
                }
            }
            .padding(.bottom, 40)
            
            HStack {
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
                Spacer()
                
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
                        .frame(width: 30)
                    )
                Spacer()
                
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
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Image(systemName: "chevron.left")
                        .bold()
                    Text("뒤로가기") // "뒤로가기" 텍스트
                }
                .foregroundStyle(.accent) // 색상 지정
                .onTapGesture {
                    navigationManager.pop()
                }
            }
        }
    }
    
    @ViewBuilder
    func MarkerListView() -> some View {
        VStack {
            HStack {
                Text("마커리스트")
                    .font(.headline)
                Spacer()
                
                tipButton()
            }
            
            VStack(spacing: 16) {
                if let music = playerModel.music {
                    ForEach(0..<3, id: \.self) { index in
                        if music.markers[index] != -1{
                            playerModel.markerButton(for: music.markers[index], index: index)
                        } else {
                            playerModel.addMarkerButton(index: index)
                        }
                    }
                } else {
                    Text("No music loaded")
                }
            }
            .padding(.bottom, 8)

        }
    }
    
    @ViewBuilder
    private func tipButton() -> some View {
        TipButtonView()
    }
}

struct TipButtonView: View {
    @State private var isTipButtonPresented = false
    
    var body: some View {
        Button(action: {
            isTipButtonPresented = true
        }) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.markerPurple)
                .padding([.top, .bottom, .leading], 10)
        }
        .fullScreenCover(isPresented: $isTipButtonPresented) {
            TipPopupView(isTipButtonPresented: $isTipButtonPresented)
                .presentationBackground(.black.opacity(0.6))
        }
        .transaction { $0.disablesAnimations = true }
    }
}
