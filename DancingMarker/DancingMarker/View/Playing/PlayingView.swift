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
    @EnvironmentObject var playerViewModel: PlayerViewModel

    var body: some View {
        VStack {
            /// 음원 정보
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
                            Task {
                                await decreasePlaybackRate()
                            }
                        }) {
                            Image(systemName: "minus")
                                .frame(width: 30, height: 30)
                                .foregroundStyle(playerViewModel.playbackRate <= 0.5 ? .inactiveGray : .white)
                        }
                        .padding(10)
                        .disabled(playerViewModel.playbackRate <= 0.5)
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await resetPlaybackRate()
                            }
                        }) {
                            Text(String(format: "x%.1f", playerViewModel.playbackRate))
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await increasePlaybackRate()
                            }
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 30, height: 30)
                                .foregroundStyle(playerViewModel.playbackRate >= 1.5 ? .inactiveGray : .white)
                        }
                        .padding(10)
                        .disabled(playerViewModel.playbackRate >= 1.5)
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
                            .frame(width: geometry.size.width * CGFloat(playerViewModel.progress), height: geometry.size.height)
                    }
                    .cornerRadius(12)
                    .contentShape(
                        Rectangle()
                            .inset(by: -6)
                    )
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                let newProgress = min(max(0, Double(value.location.x / geometry.size.width)), 1.0)
                                let newTime = newProgress * playerViewModel.duration
                                
                                Task {
                                    do {
                                        try await playerViewModel.seek(to: newTime)
                                    } catch {
                                        print("시간 이동 중 오류: \(error)")
                                    }
                                }
                            })
                    )
                }
                .frame(height: 8)
                .padding(.bottom, 3)
                
                HStack {
                    Text("\(playerViewModel.formattedProgress)")
                    Spacer()
                    Text("\(playerViewModel.formattedDuration)")
                }
            }
            .padding(.bottom, 40)
            
            /// 재생 제어 버튼들
            HStack {
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
                
                Spacer()
                
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
                        .frame(width: 30)
                    )
                
                Spacer()
                
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
                    Text("Local_Back")
                }
                .foregroundStyle(.accent)
                .onTapGesture {
                    navigationManager.pop()
                }
            }
        }
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
    
    /// 재생 속도 감소
    private func decreasePlaybackRate() async {
        let newRate = max(0.5, playerViewModel.playbackRate - 0.1)
        do {
            try await playerViewModel.setPlaybackRate(newRate)
        } catch {
            print("재생 속도 변경 중 오류: \(error)")
        }
    }
    
    /// 재생 속도 증가
    private func increasePlaybackRate() async {
        let newRate = min(1.5, playerViewModel.playbackRate + 0.1)
        do {
            try await playerViewModel.setPlaybackRate(newRate)
        } catch {
            print("재생 속도 변경 중 오류: \(error)")
        }
    }
    
    /// 재생 속도 리셋
    private func resetPlaybackRate() async {
        do {
            try await playerViewModel.setPlaybackRate(1.0)
        } catch {
            print("재생 속도 리셋 중 오류: \(error)")
        }
    }
    
    @ViewBuilder
    func MarkerListView() -> some View {
        VStack {
            HStack {
                Text("Local_MarkerList")
                    .font(.headline)
                Spacer()
                
                tipButton()
            }
            
            VStack(spacing: 16) {
                if let music = playerViewModel.currentMusic {
                    ForEach(0..<3, id: \.self) { index in
                        if music.markers[index] != -1 {
                            markerButton(for: music.markers[index], index: index)
                        } else {
                            addMarkerButton(index: index)
                        }
                    }
                } else {
                    Text("No music loaded")
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    /// 마커 버튼 생성 (기존 디자인 복원)
    @ViewBuilder
    private func markerButton(for time: TimeInterval, index: Int) -> some View {
        if playerViewModel.isEditingMarker && playerViewModel.editingMarkerIndex == index {
            editMarkerButton(for: time, index: index)
        } else {
            Button(action: {
                Task {
                    await playerViewModel.moveToMarker(at: index)
                }
            }) {
                HStack(spacing: 8) {
                    Image("addedMarker")
                    Text(playerViewModel.formattedTime(time))
                        .font(.title3)
                        .italic()
                        .foregroundColor(.black)
                }
                .frame(width: 360, height: 60)
                .background(.accent)
                .cornerRadius(12)
            }
            .contextMenu {
                Button(action: {
                    playerViewModel.startMarkerEditing(at: index)
                }) {
                    Text("Local_MarkerEdit")
                    Image(systemName: "pencil")
                }
                Button(role: .destructive, action: {
                    Task {
                        await playerViewModel.deleteMarker(at: index)
                    }
                }) {
                    Text("Local_MarkerReset")
                    Image(systemName: "eraser")
                }
            }
        }
    }
    
    /// 마커 추가 버튼 생성 (기존 디자인 복원)
    @ViewBuilder
    private func addMarkerButton(index: Int) -> some View {
        Button(action: {
            Task {
                await playerViewModel.addMarkerAtCurrentTime(at: index)
            }
        }) {
            HStack(spacing: 8) {
                Image("emptyMarker")
                Text("Local_MarkerAdd")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(width: 360, height: 60)
            .background(Color.buttonDarkGray)
            .cornerRadius(12)
        }
    }
    
    /// 마커 편집 버튼 생성 (수정된 버전)
    @ViewBuilder
    private func editMarkerButton(for marker: TimeInterval, index: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.inactiveGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image("backward1SecIcon")
                }
                .onTapGesture {
                    // ✅ MarkerService의 편집 시간을 1초 감소
                    playerViewModel.markerServiceInstance?.decreaseEditingTime()
                    print("마커 편집 시간 1초 감소")
                }
            
            HStack(spacing: 8) {
                // ✅ MarkerService의 현재 편집 시간을 표시
                Text(formattedEditingTime(index: index))
                    .font(.title3)
                    .italic()
                    .foregroundColor(.black)
            }
            .frame(width: 200, height: 60)
            .background(.accent)
            .cornerRadius(12)
            .padding(.horizontal, 6)
            
            Circle()
                .fill(.inactiveGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image("forward1SecIcon")
                }
                .onTapGesture {
                    // ✅ MarkerService의 편집 시간을 1초 증가
                    playerViewModel.markerServiceInstance?.increaseEditingTime(maxDuration: playerViewModel.duration)
                    print("마커 편집 시간 1초 증가")
                }
            
            Circle()
                .fill(.buttonDarkGray)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.green)
                }
                .padding(.leading, 10)
                .onTapGesture {
                    Task {
                        print("마커 편집 저장 버튼 클릭")
                        await playerViewModel.saveEditingMarker()
                    }
                }
        }
    }
    
    /// 편집 중인 마커의 포맷된 시간을 반환합니다
    private func formattedEditingTime(index: Int) -> String {
        if let currentEditingTime = playerViewModel.markerServiceInstance?.currentEditingTime,
           playerViewModel.isEditingMarker && playerViewModel.editingMarkerIndex == index {
            return playerViewModel.formattedTime(currentEditingTime)
        }
        return playerViewModel.formattedTime(playerViewModel.markers[index])
    }
    
    /// 현재 시간에 마커 추가
    private func addMarkerAtCurrentTime(index: Int) async {
        await playerViewModel.addMarkerAtCurrentTime(at: index)
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
