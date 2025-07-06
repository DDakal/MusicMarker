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
                VStack {
                    if let albumArt = albumArt {
                        Image(uiImage: albumArt)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.editViewAlbumGray)
                            .frame(width: 160, height: 160)
                            .overlay {
                                Image(systemName: "music.note")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.white)
                            }
                    }
                    
                    Button("Local_ChangeCoverImage") {
                        isImagePickerPresented = true
                    }
                    .font(.caption)
                    .foregroundStyle(.markerPurple)
                    .underline(true, color: .markerPurple)
                    .buttonStyle(.plain)
                }
                .padding(.top, 67)
                .padding(.bottom, 43)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Local_MusicTitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        TextField("Local_EnterMusicTitleMessage", text: $title)
                            .frame(height: 34)
                            .background(.clear)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        
                        if !title.isEmpty {
                            Button(action: { title = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Local_MusicArtist")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        TextField("Local_EnterMusicArtistMessage", text: $artist)
                            .frame(height: 34)
                            .background(Color.clear)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        
                        if !artist.isEmpty {
                            Button(action: { artist = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Spacer()
                
                Button(action: {
                    guard canSave else { return }
                    Task {
                        await saveMusic()
                        dismiss()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Local_Done")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .frame(height: 49)
                    .frame(maxWidth: .infinity)
                    .background(canSave ? Color.accentColor : Color.gray.opacity(0.3))
                    .foregroundColor(canSave ? Color.black : Color.white)
                    .cornerRadius(12)
                    .padding(.bottom, 53)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
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
            }}
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
    
    // MARK: - Private Methods
    
    private func saveMusic() async {
        music.title = title
        music.artist = artist
        music.albumArt = albumArt?.pngData()
        
        do {
            try modelContext.save()
            
            // PlayerViewModel의 currentMusic 업데이트
            if playerViewModel.currentMusic?.id == music.id {
                let updatedMusicData = MusicData(
                    id: music.id,
                    title: music.title,
                    artist: music.artist,
                    fileName: music.fileName,
                    markers: music.markers,
                    albumArt: music.albumArt
                )
                playerViewModel.currentMusic = updatedMusicData
                
                // Control Center 업데이트
                await playerViewModel.updateControlCenterNowPlaying()
                
                print("✅ 음원 수정 후 PlayerViewModel 업데이트 완료: \(updatedMusicData.title)")
            }
        } catch {
            print("음원 수정 실패: \(error.localizedDescription)")
        }
    }
}
