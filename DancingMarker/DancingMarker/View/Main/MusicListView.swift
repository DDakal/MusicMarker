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
    @EnvironmentObject var playerViewModel: PlayerViewModel

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
                    //MARK: - 코드 정리 필요
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let tappedMusic = music
                        
                        // 새로운 아키텍처로 음악 재생 처리
                        Task {
                            await handleMusicSelection(tappedMusic)
                        }
                    }

                }
                .listStyle(.inset)
                
                // 현재 음악이 있을 때 NowPlayingView 표시
                if playerViewModel.currentMusic != nil {
                    NowPlayingView()
                        .frame(height: 240)
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
                        MusicEditView(
                            music: selectedMusic,
                            didSaveMusic: $didSaveMusic
                        )
                    } else if let url = selectedFileURL {
                        MusicEditView(
                            fileURL: url,
                            didSaveMusic: $didSaveMusic
                        )
                    }
                }
            }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - New Architecture Music Handling
    
    /// 음악 선택 처리 (새로운 아키텍처)
    private func handleMusicSelection(_ music: Music) async {
        do {
            // MusicData 변환 (올바른 파라미터 순서)
            let musicData = MusicData(
                id: music.id,
                title: music.title,
                artist: music.artist,
                fileName: music.fileName,
                markers: music.markers,
                albumArt: music.albumArt  // markers 다음에 albumArt
            )
            
            if playerViewModel.currentMusic == nil || playerViewModel.currentMusic?.id != musicData.id {
                // 새로운 곡이 선택되었거나 처음 재생하는 경우
                await playerViewModel.playMusic(musicData)
                print("음원 \(musicData.title)으로 바뀜")
            } else if !playerViewModel.isPlaying {
                // 동일한 곡이지만 정지된 상태에서 재생을 눌렀을 때
                try await playerViewModel.resumeMusic()
                print("음원 \(musicData.title) 재생됨")
            } else {
                // 동일한 곡이 이미 재생 중인 경우
                print("이미 재생 중인 음원 \(musicData.title)")
            }
            
            // PlayingView로 이동
            navigationManager.push(to: .playing)
            
        } catch {
            print("음악 재생 중 오류 발생: \(error)")
        }
    }
    
    @ViewBuilder
    private func tipButton() -> some View {
        TipButtonView()
    }
    
    private func addEditedMusic(_ music: Music) {
        modelContext.insert(music)
        try? modelContext.save()
        
        // 워치로 음악 리스트 전송
        Task {
            await sendMusicListToWatch()
        }
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
                Task {
                    await deleteMusic(music)
                }
            }) {
                Text("Local_Delete")
                Image(systemName: "trash")
            }
        }
    }
    
    /// 음악 삭제 처리 (새로운 아키텍처)
    private func deleteMusic(_ music: Music) async {
        // 현재 삭제하려는 곡이 재생 중인 곡이라면 플레이어를 정지
        if playerViewModel.currentMusic?.id == music.id {
            await playerViewModel.stopMusic()  // 이제 파라미터 없음
            print("재생 중인 음악이 삭제되어 재생을 중지했습니다.")
        }
        
        // 음원 리스트에서 삭제
        if let index = musicList.firstIndex(of: music) {
            modelContext.delete(musicList[index])
            do {
                try modelContext.save()
                
                // 워치로 업데이트된 음악 리스트 전송
                await sendMusicListToWatch()
                
            } catch {
                print("음악 삭제 중 오류 발생: \(error)")
            }
        }
    }
    
    /// 워치로 음악 리스트 전송
    private func sendMusicListToWatch() async {
        do {
            try await playerViewModel.sendMusicListToWatch(musicList)  // musicList 파라미터 전달
        } catch {
            print("워치로 음악 리스트 전송 실패: \(error)")
        }
    }
    
    private func addMusic(from url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security scoped resource at \(url)")
            return
        }
        
        defer {
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
            
            // 워치로 업데이트된 음악 리스트 전송
            await sendMusicListToWatch()
            
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
        
        if title == nil || title == "Unknown Title" {
            title = url.deletingPathExtension().lastPathComponent
        }
        
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
