//
//  MusicListView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer

struct MusicListView: View {
    @Environment(NavigationManager.self) var navigationManager
    @Environment(\.modelContext) private var modelContext
    @Query var musicList: [Music] = []
    @State private var isFileImporterPresented: Bool = false
    @State private var isMusicEditViewPresented: Bool = false
    @State private var selectedFileURL: URL? = nil
    @State private var didSaveMusic: Bool = false
    @EnvironmentObject var playerModel: PlayerModel
    
    var body: some View {
        VStack {
            if musicList.isEmpty {
                VStack {
                    Spacer()
                    
                    Image("emptyBox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 332)
                        .padding(.bottom, 20)
                    Text("추가된 음악이 없어요.")
                    
                    Spacer(minLength: 250)
                }
                .font(.body)
                .foregroundStyle(.inactiveGray)
                
            } else {
                List(musicList, id: \.self) { music in
                    HStack(spacing: 10) {
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
                            Text(music.title)
                                .font(.title3)
                                .bold()
                            Text(music.artist)
                                .font(.body)
                        }
                        .lineLimit(1)
                        .contextMenu {
                            musicContextMenu(music: music)
                        }
                        Spacer()
                        
                    }
                    //MARK: - 코드 정리 필요
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let selectedMusic = music
                        
                        if playerModel.music == nil || playerModel.music?.id != selectedMusic.id {
                            // 새로운 곡이 선택되었거나 처음 재생하는 경우
                            playerModel.stopAudio()
                            playerModel.stopTimer()
                            
                            // 오디오 세션 활성화
                            try? AVAudioSession.sharedInstance().setActive(true)
                            
                            playerModel.music = selectedMusic
                            playerModel.initAudioPlayer(for: selectedMusic)
                            playerModel.isPlaying = true
                            playerModel.playAudio()
                            
                            // Now Playing 정보 설정 및 업데이트
                            playerModel.updateNowPlayingControlCenter()
                            
                            print("음원 \(playerModel.music?.title)으로 바뀜")
                        } else if !playerModel.isPlaying {
                            // 동일한 곡이지만 정지된 상태에서 재생을 눌렀을 때
                            playerModel.isPlaying = true
                            playerModel.playAudio()
                            
                            // Now Playing 정보 업데이트
                            playerModel.updateNowPlayingControlCenter()
                            
                            print("음원 \(playerModel.music?.title) 재생됨")
                        } else {
                            // 동일한 곡이 이미 재생 중인 경우
                            print("이미 재생 중인 음원 \(playerModel.music?.title)")
                        }
                        
                        // 재생 정보를 보내고, PlayingView로 이동
                        playerModel.sendPlayingInformation()
                        navigationManager.push(to: .playing)
                    }

                }
                .listStyle(.inset)
                
                if playerModel.music != nil {
                    NowPlayingView()
                        .frame(height: 240) // 미니 플레이어의 높이 조정
                        .background(.nowPlayingGray)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 20,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 20
                            )
                        )
                }
            }
        }
        .navigationTitle("내 음악")
        .toolbar {
            ToolbarItem (placement: .topBarTrailing) {
                Button(action: {
                    isFileImporterPresented.toggle()
                }) {
                    Text("추가하기")
                        .foregroundStyle(.accent)
                }
            }
        }
        .fileImporter(
                    isPresented: $isFileImporterPresented,
                    allowedContentTypes: [.audio],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            selectedFileURL = url
                            isMusicEditViewPresented = true
                            didSaveMusic = false  // 새로운 파일을 선택할 때마다 초기화
                        }
                    case .failure(let error):
                        print("Failed to import file: \(error.localizedDescription)")
                    }
                }
                .sheet(isPresented: $isMusicEditViewPresented, onDismiss: {
                    if !didSaveMusic {
                        isFileImporterPresented = true  // 저장하지 않고 닫으면 FileImporter 다시 열기
                    }
                }) {
                    if let fileURL = selectedFileURL {
                        NavigationStack {
                            MusicEditView(fileURL: fileURL, didSaveMusic: $didSaveMusic)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private func tipButton() -> some View {
        TipButtonView()
    }
    
    private func addEditedMusic(_ music: Music) {
        modelContext.insert(music)
        try? modelContext.save()
        playerModel.sendMusicListToWatch(with: musicList)
    }
    

    
    private func musicContextMenu(music: Music) -> some View {
        Group {
//            Button(action: {
//                // 수정 기능
//            }) {
//                Text("수정하기")
//                Image(systemName: "pencil")
//            }
            Button(role: .destructive, action: {
                DispatchQueue.main.async {
                    if let index = self.musicList.firstIndex(of: music) {
                        // 현재 삭제하려는 곡이 재생 중인 곡이라면, 플레이어를 정지하고 playerModel을 초기화
                        if playerModel.music?.id == music.id {
                            playerModel.stopAudio()       // 재생 중인 오디오를 정지
                            playerModel.stopTimer()       // 타이머 정지
                            playerModel.music = nil       // 음악을 nil로 설정
                            playerModel.updateNowPlayingControlCenter() // Now Playing 정보 업데이트
                        }

                        // 음원 리스트에서 삭제
                        modelContext.delete(musicList[index])
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to fetch music metadata: \(error.localizedDescription)")
                        }
                    }

                    // 워치로 업데이트된 음악 리스트 전송
                    playerModel.sendMusicListToWatch(with: musicList)
                }
            }) {
                Text("삭제하기")
                Image(systemName: "trash")
            }

        }
    }
}

extension URL {
    func appendingUniquePathComponent(_ component: String) -> URL {
        var newURL = self.appendingPathComponent(component)
        let fileManager = FileManager.default
        var fileExists = fileManager.fileExists(atPath: newURL.path)
        
        // Loop to find a unique name
        while fileExists {
            let baseName = newURL.deletingPathExtension().lastPathComponent
            let extensionName = newURL.pathExtension
            let uniqueName = "\(baseName)-\(UUID().uuidString).\(extensionName)"
            newURL = self.appendingPathComponent(uniqueName)
            fileExists = fileManager.fileExists(atPath: newURL.path)
        }
        
        return newURL
    }
}
