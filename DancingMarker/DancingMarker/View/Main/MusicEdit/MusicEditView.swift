//
//  MusicEditView.swift
//  DancingMarker
//
//  Created by 변준섭 on 6/27/24.
//

import SwiftUI
import SwiftData

struct MusicEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playerViewModel: PlayerViewModel
    
    // 기존 음원 편집 전용
    let music: Music
    @Binding var didSaveMusic: Bool
    
    @State private var selectedImgData: Data?
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var albumArt: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    
    // 변경사항 추적을 위한 초기값 저장
    @State private var initialTitle: String = ""
    @State private var initialArtist: String = ""
    @State private var albumArtChanged: Bool = false
    
    // 변경사항이 있는지 확인하는 computed property
    private var hasChanges: Bool {
        let titleChanged = title != initialTitle
        let artistChanged = artist != initialArtist
        
        return titleChanged || artistChanged || albumArtChanged
    }
    
    // 저장 버튼 활성화 조건
    private var canSave: Bool {
        let hasRequiredFields = !title.isEmpty && !artist.isEmpty
        return hasRequiredFields && hasChanges
    }

    init(music: Music, didSaveMusic: Binding<Bool>) {
        self.music = music
        self._didSaveMusic = didSaveMusic
        _title = State(initialValue: music.title)
        _artist = State(initialValue: music.artist)
        
        // 앨범아트 초기화
        var initialAlbumArt: UIImage? = nil
        if let artData = music.albumArt, let image = UIImage(data: artData) {
            initialAlbumArt = image
        }
        _albumArt = State(initialValue: initialAlbumArt)
        
        // 초기값 설정
        _initialTitle = State(initialValue: music.title)
        _initialArtist = State(initialValue: music.artist)
    }
    
    var body: some View {
        ZStack {
            Color.editViewBGBlack.edgesIgnoringSafeArea(.all)
            
            VStack {
                // 앨범아트 편집
                AlbumArtEditor(
                    albumArt: $albumArt,
                    isImagePickerPresented: $isImagePickerPresented,
                    albumArtChanged: $albumArtChanged
                )
                
                // 제목 입력
                MusicTextFieldEditor(
                    label: "Local_MusicTitle",
                    placeholder: "Local_EnterMusicTitleMessage",
                    text: $title
                )
                .padding(.bottom, 16)
                
                // 아티스트 입력
                MusicTextFieldEditor(
                    label: "Local_MusicArtist",
                    placeholder: "Local_EnterMusicArtistMessage",
                    text: $artist
                )
                
                Spacer()
                
                // 저장 버튼
                SaveButton(canSave: canSave) {
                    guard canSave else { return }
                    Task {
                        await playerViewModel.saveMusicEdit(
                            music: music,
                            title: title,
                            artist: artist,
                            albumArt: albumArt
                        )
                        didSaveMusic = true
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 16)
            .navigationTitle("Local_EditMusicNavigationTitle")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Local_Cancel")
                        .foregroundStyle(.accent)
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            SelectGalleryView(selectedImgData: $selectedImgData)
        }
        .onChange(of: selectedImgData) {
            if let data = selectedImgData, let image = UIImage(data: data) {
                albumArt = image
                albumArtChanged = true
            }
        }
        .onAppear {
            albumArtChanged = false
        }
    }
}
