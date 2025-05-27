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
    @EnvironmentObject var playerModel: PlayerModel

    @Query var musicList: [Music] = []

    @State private var isFileImporterPresented: Bool = false
    @State private var isMusicEditViewPresented: Bool = false
    @State private var selectedFileURL: URL? = nil
    @State private var didSaveMusic: Bool = false
    @State private var selectedMusic: Music? = nil
    
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
                    Text("Local_EmptyMusic")
                    
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        //  PlayerModel에 위임하여 코드 대폭 단순화
                        // 1. PlayerModel의 play 함수를 호출하여 재생 로직을 모두 위임합니다.
                        playerModel.play(music: music)
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
        .navigationTitle("Local_TitleList")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isFileImporterPresented.toggle()
                    }) {
                        Text("Local_Add")
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
                        // 파일 선택 후 바로 새 음원을 추가하는 메서드 호출
                        Task {
                            await addMusic(from: url)
                            didSaveMusic = true
                        }
                    }
                case .failure(let error):
                    print("Failed to import file: \(error.localizedDescription)")
                }
            }
            .sheet(isPresented: $isMusicEditViewPresented, onDismiss: {
                selectedMusic = nil
                if !didSaveMusic && selectedFileURL != nil {
                    isFileImporterPresented = true
                }
                selectedFileURL = nil
            }) {
                NavigationStack {
                    if let selectedMusic = selectedMusic {
                        // Existing music
                        MusicEditView(
                            music: selectedMusic,
                            didSaveMusic: $didSaveMusic
                        )
                    } else if let url = selectedFileURL {
                        // New music from URL
                        MusicEditView(
                            fileURL: url,
                            didSaveMusic: $didSaveMusic
                        )
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
            Button(action: {
                selectedMusic = music
                isMusicEditViewPresented = true
            }) {
                Text("Local_Edit")
                Image(systemName: "pencil")
            }
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
                Text("Local_Delete")
                Image(systemName: "trash")
            }
            
        }
    }
    
    private func addMusic(from url: URL) async {
        // 보안 범위 설정 시작
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security scoped resource at \(url)")
            return
        }
        
        defer {
            // 보안 범위 접근 종료
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let (title, artist, albumArt) = try await fetchMusicMetadata(from: url)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            let uniqueFileURL = documentsDirectory.appendingUniquePathComponent(url.lastPathComponent)
            
            try FileManager.default.copyItem(at: url, to: uniqueFileURL)
            
            let newMusic = Music(
                title: title,
                artist: artist,
                fileName: uniqueFileURL.lastPathComponent,
                markers: [-1, -1, -1],
                albumArt: albumArt
            )
            
            modelContext.insert(newMusic)
            try modelContext.save()
            
            playerModel.sendMusicListToWatch(with: musicList)
        } catch {
            print("Failed to fetch music metadata: \(error.localizedDescription)")
        }
    }
    
    private func fetchMusicMetadata(from url: URL) async throws -> (String, String, Data?) {
        let asset = AVAsset(url: url)
        let metadata = try await asset.load(.commonMetadata)
        
        var title: String? = nil
        var artist: String? = nil
        var albumArt: Data? = nil
        
        for item in metadata {
            if item.commonKey == .commonKeyTitle,
               let loadedTitle = try await item.load(.stringValue) {
                title = loadedTitle
            }
            if item.commonKey == .commonKeyArtist,
               let loadedArtist = try await item.load(.stringValue) {
                artist = loadedArtist
            }
            if item.commonKey == .commonKeyArtwork {
                albumArt = try await item.load(.dataValue)
            }
        }
        
        // title이 없거나 "Unknown Title"인 경우 파일 이름(확장자 제외)을 사용
        if title == nil || title == "Unknown Title" {
            title = url.deletingPathExtension().lastPathComponent
        }
        
        // artist는 메타데이터가 없을 경우 기본값 유지하거나 다른 처리를 할 수 있음
        if artist == nil || artist == "Unknown Artist" {
            artist = "Unknown Artist"
        }
        
        return (title!, artist!, albumArt)
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
