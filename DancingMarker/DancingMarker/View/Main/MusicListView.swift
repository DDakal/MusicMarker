//
//  MusicListView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import SwiftData
import AVFoundation

class SheetState: ObservableObject {
    @Published var musicToEdit: Music? = nil
    @Published var isPresented: Bool = false
    
    func editMusic(_ music: Music) {
        musicToEdit = music
        isPresented = true
    }
    
    func dismiss() {
        musicToEdit = nil
        isPresented = false
    }
}

struct MusicListView: View {
    @Environment(NavigationManager.self) var navigationManager
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    @Query var musicList: [Music] = []
    
    @State private var isFileImporterPresented: Bool = false
    @State private var didSaveMusic: Bool = false
    @StateObject private var sheetState = SheetState()
    
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
                        Task {
                            await handleMusicSelection(music)
                        }
                    }
                }
                .listStyle(.inset)
                
                // 현재 음원이 있을 때 NowPlayingView 표시
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
                    }
                }
            case .failure(let error):
                print("Failed to import file: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $sheetState.isPresented, onDismiss: {
            sheetState.dismiss()
            didSaveMusic = false
        }) {
            NavigationStack {
                if let music = sheetState.musicToEdit {
                    MusicEditView(music: music, didSaveMusic: $didSaveMusic)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Private Methods
    
    private func handleMusicSelection(_ music: Music) async {
        do {
            let musicData = MusicData(
                id: music.id,
                title: music.title,
                artist: music.artist,
                fileName: music.fileName,
                markers: music.markers,
                albumArt: music.albumArt
            )
            
            if playerViewModel.currentMusic == nil || playerViewModel.currentMusic?.id != musicData.id {
                await playerViewModel.playMusic(musicData)
            } else if !playerViewModel.isPlaying {
                try await playerViewModel.resumeMusic()
            }
            
            navigationManager.push(to: .playing)
            
        } catch {
            print("음원 재생 중 오류 발생: \(error)")
        }
    }
    
    private func musicContextMenu(music: Music) -> some View {
        Group {
            Button(action: {
                sheetState.editMusic(music)
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
    
    private func deleteMusic(_ music: Music) async {
        if playerViewModel.currentMusic?.id == music.id {
            await playerViewModel.stopMusic()
        }
        
        if let index = musicList.firstIndex(of: music) {
            modelContext.delete(musicList[index])
            do {
                try modelContext.save()
                await playerViewModel.sendMusicListToWatch()
            } catch {
                print("음원 삭제 중 오류 발생: \(error)")
            }
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
            
            await playerViewModel.sendMusicListToWatch()
            print("✅ 새 음원 추가 완료: \(title)")
        } catch {
            print("Failed to add music: \(error.localizedDescription)")
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
        
        // artist는 메타데이터가 없을 경우 기본값 설정
        if artist == nil || artist == "Unknown Artist" {
            artist = "Unknown Artist"
        }
        
        return (title!, artist!, albumArt)
    }
}

// URL 확장
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
