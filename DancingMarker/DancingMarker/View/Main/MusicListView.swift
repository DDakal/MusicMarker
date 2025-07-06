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

class SheetState: ObservableObject {
    @Published var musicToEdit: Music? = nil
    @Published var isPresented: Bool = false
    
    func editMusic(_ music: Music) {
        musicToEdit = music
        isPresented = true
        print("🔍 SheetState - editMusic 설정: \(music.title)")
    }
    
    func dismiss() {
        musicToEdit = nil
        isPresented = false
        print("🔍 SheetState - dismiss")
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
                    // 파일 선택 후 바로 새 음원을 추가하는 메서드 호출
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
                        .onAppear {
                            print("✅ 음원 편집 뷰 표시: \(music.title)")
                        }
                } else {
                    VStack(spacing: 20) {
                        Text("데이터 로딩 중...")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Button("닫기") {
                            sheetState.dismiss()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear {
                        print("🚨 예상치 못한 상황 발생")
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Private Methods
    
    /// 음원 선택 처리 (새로운 아키텍처)
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
                print("음원 \(musicData.title)으로 바뀜")
            } else if !playerViewModel.isPlaying {
                try await playerViewModel.resumeMusic()
                print("음원 \(musicData.title) 재생됨")
            } else {
                print("이미 재생 중인 음원 \(musicData.title)")
            }
            
            navigationManager.push(to: .playing)
            
        } catch {
            print("음원 재생 중 오류 발생: \(error)")
        }
    }
    
    /// 컨텍스트 메뉴 생성
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
    
    /// 음원 삭제 처리
    private func deleteMusic(_ music: Music) async {
        if playerViewModel.currentMusic?.id == music.id {
            await playerViewModel.stopMusic()
            print("재생 중인 음원이 삭제되어 재생을 중지했습니다.")
        }
        
        if let index = musicList.firstIndex(of: music) {
            modelContext.delete(musicList[index])
            do {
                try modelContext.save()
                await sendMusicListToWatch()
            } catch {
                print("음원 삭제 중 오류 발생: \(error)")
            }
        }
    }
    
    /// 워치로 음원 리스트 전송 (3단계 동기화)
    private func sendMusicListToWatch() async {
        // ✅ 3단계 동기화 시스템 사용
        await playerViewModel.sendMusicListToWatch()
    }
    
    /// 새로운 음원 추가
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
            
            await sendMusicListToWatch()
            print("✅ 새 음원 추가 완료: \(title)")
        } catch {
            print("Failed to add music: \(error.localizedDescription)")
        }
    }
    
    /// 음원 메타데이터 추출
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

// ✅ URL 확장 (기존 코드 유지)
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
