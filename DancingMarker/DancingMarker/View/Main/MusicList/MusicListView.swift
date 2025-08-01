//
//  MusicListView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import SwiftData

struct MusicListView: View {
    @Environment(NavigationManager.self) var navigationManager
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    @Query var musicList: [Music] = []
    @State private var isFileImporterPresented: Bool = false
    @State private var musicToEdit: Music? = nil
    @State private var isEditSheetPresented: Bool = false
    
    var body: some View {
        VStack {
            if musicList.isEmpty {
                emptyMusicView
            } else {
                musicListSection
                nowPlayingSection
            }
        }
        .navigationTitle("Local_TitleList")
        .toolbar {
            toolbarContent
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
        .sheet(isPresented: $isEditSheetPresented, onDismiss: {
            musicToEdit = nil
        }) {
            musicEditSheet
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Private Views
    
    private var emptyMusicView: some View {
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
    }
    
    private var musicListSection: some View {
        List(musicList, id: \.self) { music in
            MusicListItem(
                music: music,
                onTap: {
                    Task {
                        await playerViewModel.selectAndPlayMusic(
                            music,
                            navigationManager: navigationManager
                        )
                    }
                },
                onEdit: {
                    editMusic(music) // ✅ 수정됨
                },
                onDelete: {
                    Task {
                        await playerViewModel.deleteMusicFromList(
                            music,
                            modelContext: modelContext
                        )
                    }
                }
            )
        }
        .listStyle(.inset)
    }
    
    @ViewBuilder
    private var nowPlayingSection: some View {
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
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                isFileImporterPresented.toggle()
            }) {
                Text("Local_Add")
                    .foregroundStyle(.accent)
            }
        }
    }
    
    private var musicEditSheet: some View {
        NavigationStack {
            if let music = musicToEdit {
                MusicEditView(music: music, didSaveMusic: .constant(false))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func editMusic(_ music: Music) {
        musicToEdit = music
        isEditSheetPresented = true
    }
    
    private func handleFileImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    await playerViewModel.addMusicToList(
                        from: url,
                        modelContext: modelContext
                    )
                }
            }
        case .failure(let error):
            print("Failed to import file: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MusicListView()
}
