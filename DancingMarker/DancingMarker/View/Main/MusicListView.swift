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
    @Published var urlToAdd: URL? = nil
    @Published var isPresented: Bool = false
    
    func editMusic(_ music: Music) {
        urlToAdd = nil
        musicToEdit = music
        isPresented = true
        print("🔍 SheetState - editMusic 설정: \(music.title)")
    }
    
    func addMusic(_ url: URL) {
        musicToEdit = nil
        urlToAdd = url
        isPresented = true
        print("🔍 SheetState - addMusic 설정: \(url.lastPathComponent)")
    }
    
    func dismiss() {
        musicToEdit = nil
        urlToAdd = nil
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
                    sheetState.addMusic(url)  
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
                            print("✅ 음악 편집 뷰 표시: \(music.title)")
                        }
                } else if let url = sheetState.urlToAdd {
                    MusicEditView(fileURL: url, didSaveMusic: $didSaveMusic)
                        .onAppear {
                            print("✅ 음악 추가 뷰 표시: \(url.lastPathComponent)")
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
    
    /// 음악 선택 처리 (새로운 아키텍처)
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
            print("음악 재생 중 오류 발생: \(error)")
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
    
    /// 음악 삭제 처리
    private func deleteMusic(_ music: Music) async {
        if playerViewModel.currentMusic?.id == music.id {
            await playerViewModel.stopMusic()
            print("재생 중인 음악이 삭제되어 재생을 중지했습니다.")
        }
        
        if let index = musicList.firstIndex(of: music) {
            modelContext.delete(musicList[index])
            do {
                try modelContext.save()
                await sendMusicListToWatch()
            } catch {
                print("음악 삭제 중 오류 발생: \(error)")
            }
        }
    }
    
    /// 워치로 음악 리스트 전송
    private func sendMusicListToWatch() async {
        do {
            try await playerViewModel.sendMusicListToWatch(musicList)
        } catch {
            print("워치로 음악 리스트 전송 실패: \(error)")
        }
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
